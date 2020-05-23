# Copyright (c) 2020, Massimiliano Dal Mas
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the distribution
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module XOPTIMA
  class OCProblem

  private 

    ##
    # It calculates the `nu` vector as
    # ```
    #               dx(zeta)
    # mass_matrix * --------
    #                dzeta
    # ```
    def __nu
      # The vector is returned as an array
      return @mass_matrix * @states.map { |sv| var(:"#{sv.name}_dot")[@independent] }
    end

    ##
    # It calculates the `eta` vector as
    # ```
    # mass_matrix * [lambda1(t), lambda2(t),...]^T
    # ```
    # This method must be called after `__h_term` to
    # generate the `lambdas` vector
    def __eta
      # The vector is returned as an array
      return @mass_matrix.transpose * @lambdas
    end

    ##
    # Calculates the H term as
    # ```
    # Sum(lambdaj(t) * fj) + lagrange
    # ```
    # This method saves the `lambdaj(t)` elements in `@lambdas`
    def __h_term 
      h = 0
      @rhs.each_with_index do |f, i| 
        lambda_i = var(:"lambda#{i+1}__xo")[@independent]
        @lambdas << lambda_i
        h += lambda_i * f
      end
      return h + @lagrange
    end

    ##
    # It calculates the B term as:
    # ```
    # Sum( (xj(zeta_k) - xj_k) * omegaj ) + mayer
    # ```
    # In which `k` is the initial or final side.
    # This method saves the `omegaj` elements in `@omegas`
    def __b_term
      b = 0
      i = 1
      @final.each do |bj, vj| 
        omega_i = var(:"omega#{i}__xo")
        @omegas << omega_i
        b += (bj[@right] - vj) * omega_i
        i += 1
      end

      @initial.each do |bj, vj| 
        omega_i = var(:"omega#{i}__xo")
        @omegas << omega_i
        b += (bj[@left] - vj) * omega_i
        i += 1
      end

      @cyclic.each do |bj, vj| 
        omega_i = var(:"omega#{i}__xo")
        @omegas << omega_i
        b += (bj[var(@left)] - vj[@right]) * omega_i
        i += 1
      end

      @generic.each do |bj, vj| 
        omega_i = var(:"omega#{i}__xo")
        @omegas << omega_i
        b += (bj[@left] - vj) * omega_i
        i += 1
      end
      return b + @mayer
    end 

    # It calculates the bc vector that is the gradient of `B`
    # w.r.t. the `omegas vector.
    # The vector is represented as an array
    def __bc
      @omegas.map { |omegaj|  @B.diff(omegaj) }
    end
    
    # It calculates the derivative of `H` w.r.t. the states `x`.
    # It returns a vector as an array
    def __dH_dx
      @states.map { |s| @H.diff(s) }
    end

    # It calculates the derivative of H w.r.t. the controls `u`.
    # It returns a vector as an array
    def __dH_du
      @controls.map { |c| @H.diff(c) }
    end

    # It calculates the derivative of H w.r.t. the parameters `p`.
    # It returns a vector as an array
    def __dH_dp
      @params.map { |p| @H.diff(p) }
    end

    ##
    # It calculates the jacobian of the right hand side
    # w.r.t. the states.
    def __df_dx 
      __jacobian(@rhs, @states)
    end

    ##
    # It calculates the jacobian of the right hand side
    # w.r.t. the controls.
    def __df_du
      if @controls.empty?
        Matrix.empty(@rhs.size, 0)
      else
        __jacobian(@rhs, @controls)
      end
    end

    ##
    # It calculates the jacobian of the right hand side
    # w.r.t. the parameters.
    def __df_dp
      __jacobian(@rhs, @parameters)
    end

    ##
    # Routine to calculate the jacobians.
    #
    # arguments:
    # * v : array of function to derivate
    # * q : set of variables w.r.t. calculate the differential
    def __jacobian(v, q)
      return Matrix.empty(v.size, 0) if q.empty?
      m = Array.new(v.size) do |i|
        v_i = v[i]
        Array.new(q.size) do |j|
          diff(v_i, q[j])
        end
      end
      Matrix.new(m)
    end

    ##
    # It calculates the penalty `P` as:
    # ```
    # Sum(scale * Ucontrol(U(zeta), min, max))
    # ```
    # It also checks which control bounds can be
    # optimized (saved in `@optimizable_cb`)
    def __generate_penalty
      _P = 0
      @control_bounds.each do |cb|
        cb_x = cb.control[@independent]
        _P += cb.scale * var(cb.label)[cb_x, cb.min, cb.max]
        @optimizable_cb << cb if __is_optimizable_cb(cb, cb_x)
      end
      _P
    end

    ##
    # It checks if a control bound is optimizable.
    # A control bound can be optimized if `dH/dUj`
    # and its max and min values do not depend on any control
    def __is_optimizable_cb(cb, cb_x)
      opt = true
      dh_dc = @H.diff cb_x
      @controls.each do |c|
        name = c.to_var
        opt &&= !(cb.min.depends_on?(name) || cb.min.depends_on?(c))
        opt &&= !(cb.max.depends_on?(name) || cb.max.depends_on?(c))
        opt &&= !(dh_dc.depends_on?(name) || dh_dc.depends_on?(c))
      end
      opt
    end

    # It collects all the parameters that do not appear in the
    # states, controls, lambdas, omegas, independent, left and right
    def __collect_parameters
      @rhs.each           { |rhs| rhs.free_vars @parameters }
      @mass_matrix.each   { |el| el.free_vars @parameters   }
      @generic.each_value { |v| v.free_vars @parameters }
      @initial.each_value { |v| v.free_vars @parameters }
      @final.each_value   { |v| v.free_vars @parameters }
      @cyclic.each_value  { |v| v.free_vars @parameters }
      @lagrange.free_vars(@parameters) if @lagrange.is_symbolic?
      @P.free_vars @parameters

      @states.each do |s|
        @parameters.delete s.to_var
      end
      @controls.each do |c|
        @parameters.delete c.to_var
      end
      @lambdas.each do |l|
        @parameters.delete l.to_var
      end 
      @omegas.each do |o|
        @parameters.delete o 
      end
      @parameters.delete @independent
      @parameters.delete @left 
      @parameters.delete @right
      @parameters
    end

    def __states_i_f
      states_i_f = []
      dict       = { @independent => @left}
      @states.each { |s| states_i_f << s.subs(dict)  }
      dict       = { @independent => @right}
      @states.each { |s| states_i_f << s.subs(dict) }
      return states_i_f
    end

    #############################################################################
    #  ____                              __  __       _        _                #
    # / ___| _ __   __ _ _ __ ___  ___  |  \/  | __ _| |_ _ __(_) ___ ___  ___  #
    # \___ \| '_ \ / _` | '__/ __|/ _ \ | |\/| |/ _` | __| '__| |/ __/ _ \/ __| #
    #  ___) | |_) | (_| | |  \__ \  __/ | |  | | (_| | |_| |  | | (_|  __/\__ \ #
    # |____/| .__/ \__,_|_|  |___/\___| |_|  |_|\__,_|\__|_|  |_|\___\___||___/ #
    #       |_|                                                                 #
    #############################################################################
    
    def __DgDxlp
    end

    def __DgDu
    end

    def __DjumpDxlp
    end

    def __DbcDx
      return __jacobian(@bc,@states_i_f).to_sparse("DbcDx")
    end

    def __DbcDp
      return __jacobian(@bc,@params).to_sparse("DbcDp")
    end

    def __DadjointBCDx

      return __jacobian(@DadjointBC, @states_i_f).to_sparse("DadjointBCDx")
    end

    def __DadjointBCDp
      return __jacobian(@DadjointBC, @params).to_sparse("DadjointBCDp")
    end

    def __DHxDx
      return __jacobian(@dH_dx, @states).to_sparse("DHxDx")
    end

    def __DHxDp
      return __jacobian(@dH_dx, @params).to_sparse("DHxDp")
    end

    def __DHuDx
      return __jacobian(@dH_du, @states).to_sparse("DHuDx")
    end

    def __DHuDp
      return __jacobian(@dH_du, @params).to_sparse("DHuDp")
    end

    def __DHpDp
      return __jacobian(@dH_dp, @params).to_sparse("DHpDp")
    end

    def __Drhs_odeDx
      return __jacobian(@rhs, @states).to_sparse("Drhs_odeDx")
    end

    def __Drhs_odeDp
      return __jacobian(@rhs, @params).to_sparse("Drhs_odeDp")
    end

    def __Drhs_odeDu
      return __jacobian(@rhs, @controls).to_sparse("Drhs_odeDu")
    end

    def __A_ode
      return @mass_matrix.to_sparse("A_ode")
    end

    def __DetaDx
      return __jacobian(@eta, @states).to_sparse("DetaDx")
    end

    def __DetaDp
      return __jacobian(@eta, @params).to_sparse("DetaDp")
    end

    def __DnuDx
      return __jacobian(@nu, @states).to_sparse("DnuDx")
    end

    def __DnuDp
      return __jacobian(@nu, @params).to_sparse("DnuDp")
    end


  end
end
