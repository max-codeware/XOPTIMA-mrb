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

    def __nu
      return @mass_matrix * @states.map { |sv| var(:"#{sv.name}_dot")[@independent] }
    end

    def __eta
      return @mass_matrix.transpose * @lambdas
    end

    def __h_term 
      h = 0
      @lambdas = []
      @rhs.each_with_index do |f, i| 
        lambda_i = var(:"lambda#{i+1}__xo")[@independent]
        @lambdas << lambda_i
        h += lambda_i * f
      end
      return h + @lagrange
    end

    def __b_term
      b = 0
      i = 1
      @final.each do |bj, vj| 
        b += (bj[@right] - vj) * var(:"omega#{i}__xo")
        i += 1
      end

      @initial.each do |bj, vj| 
        b += (bj[@left] - vj) * var(:"omega#{i}__xo")
        i += 1
      end

      @cyclic.each do |bj, vj| 
        b += (bj[var(@left)] - vj[@right]) * var(:"omega#{i}__xo")
        i += 1
      end

      @generic.each do |bj, vj| 
        b += (bj[@left] - vj) * var(:"omega#{i}__xo")
        i += 1
      end
      return b + @mayer
    end 

    def __df_dx 
      __jacobian(@rhs, @states)
    end

    def __df_du
      if @controls.empty?
        # TODO
      else
        __jacobian(@rhs, @controls)
      end
    end

    def __df_dp
      __jacobian(@rhs, @parameters)
    end

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

  end
end
