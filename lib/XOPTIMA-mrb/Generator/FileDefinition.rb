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
  
  ##
  # This class handles the problem description
  # and generates the temporary code files.
  # This class shall not be used by the final user.
  class FileDefinition < FileGenerator

    define_file("eta",       mode: :vec, variable: :eta      )
    define_file("g",         mode: :vec, variable: :g        )
    define_file("jump",      mode: :vec, variable: :jump     )
    define_file("nu",        mode: :vec, variable: :nu       )
    define_file("rhs_ode",   mode: :vec, variable: :rhs      )
    define_file("Hp",        mode: :vec, variable: :dH_dp    )
    define_file("Hu",        mode: :vec, variable: :dH_du    )
    define_file("Hx",        mode: :vec, variable: :dH_dx    )
    define_file("DmayerDx",  mode: :vec, variable: :Dmayer_dx) 
    define_file("DmayerDp",  mode: :vec, variable: :Dmayer_dp)
    define_file("adjointBC", mode: :vec, variable: :adjointBC)
    define_file("DJDx",      mode: :vec, variable: :dJ_dx    )
    define_file("DJDp",      mode: :vec, variable: :dJ_dp    )
    define_file("DJDu",      mode: :vec, variable: :dJ_du    )
    define_file("DmDu",      mode: :vec, variable: :dm_du    )

    define_file("u_check") do |io|
      @ocproblem.control_bounds.each_with_index do |cb,i|
        cb_x = @dict[cb.control[@ocproblem.independent]]
        Check.not_nil(cb_x)
        io.puts "dummy_#{i + 1} = #{cb.label}___dot___check_range(#{cb_x}, #{cb.min.subs(@dict)}, #{cb.max.subs(@dict)});" 
      end
    end

    define_file("u") do |io|
      io.puts "// Solver not implemented in Ruby"
      @ocproblem.controls.each_with_index do |c, i|
        io.puts "result__[#{i}] = 0;"
      end
    end


    # This file is generated renaming the independent variable as `t1`
    # and assigning to it the value of `Q__[0]`.
    # Then, it is substituted into the expression after the
    # dictionary for code generation (we want to subs only the remaining
    # independent variable stated as free one)
    define_file("x_guess") do |io|
      io.puts "t1 = Q__[0];"
      states = @ocproblem.states
      dict   = {@ocproblem.independent => var(:t1)}
      @ocproblem.state_guess.each do |s, g|
        index = states.index { |state| state.name == s }
        #g = g.symdescfy # TO FIX
        io.puts "result__[#{index}] = #{g.subs(@dict).subs(dict)};"
      end
    end

    define_file("bc") do |io|
      i = -1
      @ocproblem.final.each do |k, v|
        exp = k[@ocproblem.right] - v 
        io.puts "result__[#{i += 1}] = #{exp.subs(@dict)};"
      end
        
      @ocproblem.initial.each do |k, v|
        exp = k[@ocproblem.left] - v 
        io.puts "result__[#{i += 1}] = #{exp.subs(@dict)};"
      end
      # @ocproblem.cyclic.each
      # @ocproblem.generic.each
    end 

    define_file("u_guess") do |io|
      # TODO: temporary workaround. Needs to be implemented
      io.puts "result[0] = 0;"
    end

    define_file("Jp_fun") do |io|
      # TODO: this part must be implemented
      io.puts "result__ = 0;"
    end

    define_file("mayer_target") do |io|
      io.puts "result__ = #{@ocproblem.mayer.subs(@dict)};"
    end

    define_file("lagrange_target") do |io|
      io.puts "result__ = #{@ocproblem.lagrange.subs(@dict)};"
    end
 
    define_file("H_fun") do |io|
       io.puts "result__ = #{@ocproblem.H.subs(@dict)};"
    end

    define_file("Jp_controls") do |io|
      io.puts "result__ = #{@ocproblem.P.subs(@dict)};"
    end

    define_file("q") do |io|
      io.puts "result__[0] = s;"
    end

    define_file("DuDxlp") do |io|
      io.puts "UTILS_ERROR0(\"DuDxlp not defined\");"
    end

    define_file("m_fun") do |io|
      io.puts "result__ = #{@ocproblem.m.subs(@dict)};"
    end

    define_file("cell_check") do |io|
    end

    define_file("node_check") do |io|
    end

    define_file("pars_check") do |io|
    end

    define_file("l_guess") do |io|
    end

    define_file("post") do |io|
    end

    define_file("integrated_post") do |io|
    end

    define_file("p_guess") do |io|
    end

  end
end