# Copyright (c) 2021, Massimiliano Dal Mas
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
    
    ####################################################
    #  ____        __ _       _ _   _                  #
    # |  _ \  ___ / _(_)_ __ (_) |_(_) ___  _ __  ___  #
    # | | | |/ _ \ |_| | '_ \| | __| |/ _ \| '_ \/ __| #
    # | |_| |  __/  _| | | | | | |_| | (_) | | | \__ \ #
    # |____/ \___|_| |_|_| |_|_|\__|_|\___/|_| |_|___/ #
    ####################################################

    ##
    # Calculates the H term as
    # ```
    # Sum(lambdaj(t) * fj) + lagrange
    # ```
    # This method saves the `lambdaj(t)` elements in `@lambdas`
    define :H do
      h = 0
      @rhs.each_with_index do |f, i| 
        lambda_i = var(:"lambda#{i+1}__xo")[@independent]
        @lambdas << lambda_i
        h += lambda_i * f
      end
      next h + @lagrange
    end

    ##
    # It calculates the B term as:
    # ```
    # Sum( (xj(zeta_k) - xj_k) * omegaj ) + mayer
    # ```
    # In which `k` is the initial or final side.
    # This method saves the `omegaj` elements in `@omegas`
    define :B do
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
      next b + @mayer
    end 

    # It creates a vector cointaining, in the order, the states
    # calculated in `zeta_i` and the states calculated in `zeta_f`.
    # `zeta` is the independent variable specified in the problem 
    # description.
    define :states_i_f do
      states_n   = @states.size
      states_i_f = Array.new(@states.size * 2)
      @states.each_with_index do |state, j|
        name = state.name
        states_i_f[j] = name[@left]
        states_i_f[j + states_n] = name[@right]
      end
      next states_i_f
    end

    # It creates a vector cointaining, in the order, the lambdas
    # calculated in `zeta_i` and the lambdas calculated in `zeta_f`.
    # `zeta` is the independent variable specified in the problem 
    # description.
    define :lambdas_i_f do
      lambdas_n   = @lambdas.size
      lambdas_i_f = Array.new(lambdas_n * 2)
      @lambdas.each_with_index do |lambdaj, j|
        name = lambdaj.name
        lambdas_i_f[j] = name[@left]
        lambdas_i_f[j + lambdas_n] = name[@right]
      end
      next lambdas_i_f
    end

    ##
    # It calculates the `nu` vector as
    # ```
    #               dx(zeta)
    # mass_matrix * --------
    #                dzeta
    # ```
    define :nu do
      # The vector is returned as an array
      next @mass_matrix * @states.map { |sv| var(:"#{sv.name}_dot")[@independent] }
    end
  
    ##
    # It calculates the `eta` vector as
    # ```
    # mass_matrix * [lambda1(t), lambda2(t),...]^T
    # ```
    # This method must be called after `__h_term` to
    # generate the `lambdas` vector
    define :eta do
      # The vector is returned as an array
      next @mass_matrix.transpose * @lambdas
    end

    ##
    # It calculates the penalty `P` as:
    # ```
    # Sum(scale * Ucontrol(U(zeta), min, max))
    # ```
    # It also checks which control bounds can be
    # optimized (saved in `@optimizable_cb`)
    define :P do
      _P = 0
      @control_bounds.each do |cb|
        cb_x = cb.control[@independent]
        _P += cb.scale * var(cb.label)[cb_x, cb.min, cb.max]
        @optimizable_cb << cb if __is_optimizable_cb(cb, cb_x)
      end
      next _P
    end

    define :J do
      next @P
    end

    ##
    # It calculates the jacobian of the right hand side
    # w.r.t. the states.
    define :df_dx do
      next __jacobian(@rhs, @states)
    end

    ##
    # It calculates the jacobian of the right hand side
    # w.r.t. the controls.
    define :df_du do
      if @controls.empty?
        Matrix.empty(@rhs.size, 0)
      else
        __jacobian(@rhs, @controls)
      end
    end

    ##
    # It calculates the jacobian of the right hand side
    # w.r.t. the parameters.
    define :df_dp do
      next __jacobian(@rhs, @params)
    end

    # It calculates the derivative of `H` w.r.t. the states `x`.
    # It returns a vector as an array
    define :dH_dx do
      next @states.map { |s| @H.diff(s) }
    end

    # It calculates the derivative of H w.r.t. the controls `u`.
    # It returns a vector as an array
    define :dH_du do
      next @controls.map { |c| @H.diff(c) }
    end

    # It calculates the derivative of H w.r.t. the parameters `p`.
    # It returns a vector as an array
    define :dH_dp do
      next @params.map { |p| @H.diff(p) }
    end

    # It calculates the derivative of `J` w.r.t. the states `x`.
    # It returns a vector as an array
    define :dJ_dx do
      next @states.map { |s| @J.diff(s) }
    end

    # It calculates the derivative of `J` w.r.t. the controls `u`.
    # It returns a vector as an array
    define :dJ_du do
      next @controls.map { |c| @J.diff(c) }
    end

    # It calculates the derivative of `J` w.r.t. the parameters `p`.
    # It returns a vector as an array
    define :dJ_dp do
      next @params.map { |p| @J.diff(p) }
    end

    define :m do
      next @J + @rhs.zip(@nu).inject(0) { |acc, i| acc + (i[0] - i[1]) ** 2}
    end

    define :dm_du do    
      next @controls.map { |c| @m.diff(c) }
    end

    # It calculates the bc vector that is the gradient of `B`
    # w.r.t. the `omegas vector.
    # The vector is represented as an array
    define :bc do
      next @omegas.map { |omegaj|  @B.diff(omegaj) }
    end

    define :Dmayer_dx do
      next @states_i_f.map { |x| @mayer.diff(x) }
    end

    define :Dmayer_dp do
      next @params.map { |p| @mayer.diff(p) }
    end

    # It calculates the adjointBC vector
    define :adjointBC do
      dict1 = {}
      dict2 = {}
      states_i = @states_i_f[0...@states.size]
      states_f = @states_i_f[@states.size..-1]

      states.each_with_index do |s, i|
        dict1[s] = states_i[i]
        dict2[s] = states_f[i]
      end

      size = @lambdas.size
      @lambdas.each_with_index do |l, i|
        dict1[l] = @lambdas_i_f[i]
        dict2[l] = @lambdas_i_f[i + size]
      end

      pc1 = states_i.each_with_index.map { |xj, i| (@B.diff(xj) + @eta[i]).subs(dict1)}
      pc2 = states_f.each_with_index.map { |xj, i| (@B.diff(xj) - @eta[i]).subs(dict2)}
      next pc1.concat pc2
    end

    # It calculates the `g` vector as
    # ```
    # d (H + P)
    # _________
    #    du
    # ```
    define :g do
      h_p = @H + @P
      next @controls.map { |c|  h_p.diff(c) }
    end

    ##
    # It calculates the jump vector as
    # `[statej[left] - statej[right], ... , lambdaj[left] - lambdaj[right], ...]`
    define :jump do
      jump = []
      states_n = @states.size
      states_n.times do |j|
        jump << @states_i_f[j + states_n] - @states_i_f[j]
      end
      lambdas_n = @lambdas.size
      lambdas_n.times do |j|
        jump << @lambdas_i_f[j + lambdas_n] - @lambdas_i_f[j]
      end
      next jump
    end


    ##########################################################
    #     _    ____ ____ _____ ____ ____   ___  ____  ____   #
    #    / \  / ___/ ___| ____/ ___/ ___| / _ \|  _ \/ ___|  #
    #   / _ \| |  | |   |  _| \___ \___ \| | | | |_) \___ \  #
    #  / ___ \ |__| |___| |___ ___) |__) | |_| |  _ < ___) | #
    # /_/   \_\____\____|_____|____/____/ \___/|_| \_\____/  #
    ##########################################################


    # It collects all the parameters that do not appear in the
    # states, controls, lambdas, omegas, independent, left and right
    define_accessor :__collect_parameters, auto: true do
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
      @aux_params.each_key do |k|
        @parameters.delete k
      end

      @parameters.delete @independent
      @parameters.delete @left 
      @parameters.delete @right
      next @parameters
    end

    define_accessor :__is_optimizable_cb do |cb, cb_x|
      opt = true
      dh_dc = @H.diff cb_x
      @controls.each do |c|
        name = c.to_var
        opt &&= !(cb.min.depends_on?(name) || cb.min.depends_on?(c))
        opt &&= !(cb.max.depends_on?(name) || cb.max.depends_on?(c))
        opt &&= !(dh_dc.depends_on?(name) || dh_dc.depends_on?(c))
      end
      next opt
    end

    ##
    # Routine to calculate the jacobians.
    #
    # arguments:
    # * v : array of function to derivate
    # * q : set of variables w.r.t. calculate the differential
    define_accessor :__jacobian do |v, q|
      return Matrix.empty(v.size, 0) if q.empty?
      m = Array.new(v.size) do |i|
        v_i = v[i]
        Array.new(q.size) do |j|
          diff(v_i, q[j])
        end
      end
      next  Matrix.new(m)
    end

    #############################################################################
    #  ____                              __  __       _        _                #
    # / ___| _ __   __ _ _ __ ___  ___  |  \/  | __ _| |_ _ __(_) ___ ___  ___  #
    # \___ \| '_ \ / _` | '__/ __|/ _ \ | |\/| |/ _` | __| '__| |/ __/ _ \/ __| #
    #  ___) | |_) | (_| | |  \__ \  __/ | |  | | (_| | |_| |  | | (_|  __/\__ \ #
    # |____/| .__/ \__,_|_|  |___/\___| |_|  |_|\__,_|\__|_|  |_|\___\___||___/ #
    #       |_|                                                                 #
    #############################################################################

    define_sparse :DgDxlp do
      xlp = []
      @states.each_with_index do |s, j|
        xlp << s << @lambdas[j]
      end
      xlp.concat @params
      next __jacobian(@g, xlp).to_sparse("DgDxlp")
    end

    define_sparse :DgDu do
      next __jacobian(@g, @controls).to_sparse("DgDu")
    end

    define_sparse :DjumpDxlp do
      s_size = @states.size
      l_size = @lambdas.size
      xlp = @states_i_f[0...s_size].concat(
        @lambdas_i_f[0...l_size],
        @states_i_f[s_size..-1],
        @lambdas_i_f[l_size..-1]
      )
      next __jacobian(@jump, xlp).to_sparse("DjumpDxlp")
    end

    define_sparse :DbcDx do
      next __jacobian(@bc,@states_i_f).to_sparse("DbcDx")
    end

    define_sparse :DbcDp do
      next __jacobian(@bc,@params).to_sparse("DbcDp")
    end

    define_sparse :DadjointBCDx do
      next __jacobian(@adjointBC, @states_i_f).to_sparse("DadjointBCDx")
    end

    define_sparse :DadjointBCDp do
      next __jacobian(@adjointBC, @params).to_sparse("DadjointBCDp")
    end

    define_sparse :DHxDx do
      next __jacobian(@dH_dx, @states).to_sparse("DHxDx")
    end

    define_sparse :DHxDp do
      next __jacobian(@dH_dx, @params).to_sparse("DHxDp")
    end

    define_sparse :DHuDx do
      next __jacobian(@dH_du, @states).to_sparse("DHuDx")
    end

    define_sparse :DHuDp do
      next __jacobian(@dH_du, @params).to_sparse("DHuDp")
    end

    define_sparse :DHpDp do
      next __jacobian(@dH_dp, @params).to_sparse("DHpDp")
    end

    define_sparse :Drhs_odeDx do
      next __jacobian(@rhs, @states).to_sparse("Drhs_odeDx")
    end

    define_sparse :Drhs_odeDp do
      next __jacobian(@rhs, @params).to_sparse("Drhs_odeDp")
    end

    define_sparse :Drhs_odeDu do
      next __jacobian(@rhs, @controls).to_sparse("Drhs_odeDu")
    end

    define_sparse :A_ode do
      next @mass_matrix.to_sparse("A_ode")
    end

    define_sparse :DetaDx do
      next __jacobian(@eta, @states).to_sparse("DetaDx")
    end

    define_sparse :DetaDp do
      next __jacobian(@eta, @params).to_sparse("DetaDp")
    end

    define_sparse :DnuDx do
      next __jacobian(@nu, @states).to_sparse("DnuDx")
    end

    define_sparse :DnuDp do
      next __jacobian(@nu, @params).to_sparse("DnuDp")
    end

    define_sparse :DmDuu do
      next __jacobian(@dm_du, @controls).to_sparse("DmDuu")
    end

  end
end



