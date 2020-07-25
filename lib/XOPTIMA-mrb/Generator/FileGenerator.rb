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

if ENGINE.ruby?
  require "erb"
end

module XOPTIMA
  
  ##
  # This class handles the problem description
  # and generates the temporary code files.
  # This class shall not be used by the final user.
  class FileGenerator

    include GeneratorHelper

  	# It initializes the instance saving the `ocproblem`
    # description passes as argument.
    # It also creates a directory named `OCP_tmp` where all
    # the generated files are placed.
    def initialize(ocproblem)
  		@ocproblem = ocproblem
      Dir.mkdir("OCP_tmp") unless Dir.exist? "OCP_tmp"
  	end

    # Generic method that calls all the subroutines for the full
    # generation of the problem files
    def render_files
      @dict = @ocproblem.substitution_dict
      generate_ocp_rb
      generate_sparse_mx_files
      generate_precalculated
      generate_rhs_ode
      generate_checks
      generate_guess
      generate_H_files
      generate_targets
      generate_bc
      generate_adjointBC
      generate_post
      generate_jp
      generate_q_u
      generate_DuDxlp
    end
    
    ##
    # It renders and generates the file `OCP.rb`
    def generate_ocp_rb
      log_report("OCP.rb") do
      
        # Loading templates and creating renders
        ocp_rb_render         = make_template_render(OCPrb, OCPNameSet)
        user_f_class_i_render = make_template_render(UserFunctionsCI, UserFCINameSet)

        # Rendering content of `DATA[:UserFunctionsClassInstances]`
        user_f_class_i = render_user_functions_ci(user_f_class_i_render)
      
        # Rendering `OCP.rb'
        ocp_rb = ocp_rb_render.render(@ocproblem, user_f_class_i)

        open("OCP_tmp/OCP.rb", "w") { |io| io.puts ocp_rb }
      end
    end

    ##
    # It generates all the files of the sparse matrices
    def generate_sparse_mx_files
      @ocproblem.sparse_mxs.each do |mx|
        write_matrix("#{mx.label}.c_code", mx, @dict)
      end
    end
    
    # it Generates the files for the expressions generated
    # in OCProblem. In particular:
    #   * eta
    #   * g
    #   + jump
    #   * nu
    #   * H
    def generate_precalculated
      write_with_log("eta.c_code") do |io| 
        write_array(@ocproblem.eta, io)
      end

      write_with_log("g.c_code") do |io| 
        write_array(@ocproblem.g, io)
      end

      write_with_log("jump.c_code") do |io|
        write_array(@ocproblem.jump, io)
      end 

      write_with_log("nu.c_code") do |io|
        write_array(@ocproblem.nu, io)
      end

      write_with_log("H_fun.c_code") do |io|
        io.puts "result__ = #{@ocproblem.H.subs(@dict)};"
      end
    end

    ##
    # It generates the file for the right-hand side of the ODE
    def generate_rhs_ode
      write_with_log("rhs_ode.c_code") do |io|
        write_array(@ocproblem.rhs, io)
      end
    end

    ##
    # It generates the files for checks
    def generate_checks
      write_with_log("cell_check.c_code") do |io|
      end

      write_with_log("node_check.c_code") do |io|
      end

      write_with_log("pars_check.c_code") do |io|
      end

      write_with_log("u_check.c_code") do |io|
        @ocproblem.control_bounds.each_with_index do |cb,i|
          cb_x = @dict[cb.control[@ocproblem.independent]]
          Check.not_nil(cb_x)
          io.puts "dummy_#{i + 1} = #{cb.label}___dot___check_range(#{cb_x}, #{cb.min.subs(@dict)}, #{cb.max.subs(@dict)});" 
        end
      end
    end

    ##
    # It generates the files for guesses
    def generate_guess
      write_with_log("l_guess.c_code") do |io|
      end

      write_with_log("u_guess.c_code") do |io|
        # TODO: temporary workaround. Needs to be implemented
        io.puts "result[0] = 0;"
      end

      # This file is generated renaming the independent variable as `t1`
      # and assigning to it the value of `Q__[0]`.
      # Then, it is substituted into the expression after the
      # dictionary for code generation (we want to subs only the remaining
      # independent variable stated as free one)
      write_with_log("x_guess.c_code") do |io|
        io.puts "t1 = Q__[0];"
        states = @ocproblem.states
        dict   = {@ocproblem.independent => var(:t1)}
        @ocproblem.state_guess.each do |s, g|
          index = states.index { |state| state.name == s }
          io.puts "result__[#{index}] = #{g.subs(@dict).subs(dict)};"
        end
      end

      write_with_log("p_guess.c_code") do |io|
      end
    end

    ##
    # It generates three files coding:
    #   * dH/dp
    #   * dh/du
    #   * dH/dx
    def generate_H_files
      write_with_log("Hp.c_code") do |io|
        write_array(@ocproblem.dH_dp, io)
      end

      write_with_log("Hu.c_code") do |io|
        write_array(@ocproblem.dH_du, io)
      end

      write_with_log("Hx.c_code") do |io|
        write_array(@ocproblem.dH_dx, io)
      end
    end

    ##
    # It generates the files for the lagrange and
    # mayer targets
    def generate_targets
      write_with_log("mayer_target.c_code") do |io|
        io.puts "result__ = #{@ocproblem.mayer.subs(@dict)};"
      end

      write_with_log("lagrange_target.c_code") do |io|
        io.puts "result__ = #{@ocproblem.lagrange.subs(@dict)};"
      end
    end

    ##
    # It generates the `bc` file where the
    # boundary conditions are coded
    def generate_bc
      write_with_log("bc.c_code") do |io|
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
    end

    ##
    # It generates the `adjointBC` file
    def generate_adjointBC
      write_with_log("adjointBC.c_code") do |io|
        write_array(@ocproblem.adjointBC, io)
      end
    end

    ##
    # It generates the `post` and integrated_post`
    # files
    def generate_post
      write_with_log("post.c_code") do |io|
      end

      write_with_log("integrated_post.c_code") do |io|
      end
    end

    ##
    # It generates the `Jp_controls` and `Jp_fun`
    # files
    def generate_jp
      write_with_log("Jp_controls.c_code") do |io|
        io.puts "result__ = #{@ocproblem.P.subs(@dict)};"
      end

      write_with_log("Jp_fun.c_code") do |io|
        # TODO: this part must be implemented
        io.puts "result__ = 0;"
      end
    end

    ##
    # It generates the `q` and `u` file
    def generate_q_u
      write_with_log("q.c_code") do |io|
        io.puts "result__[0] = s;"
      end

      write_with_log("u.c_code") do |io|
        io.puts "// Solver not implemented in Ruby"
        @ocproblem.controls.each_with_index do |c, i|
          io.puts "result__[#{i}] = 0;"
        end
      end
    end

    ##
    # It generates the `DuDxlp` file
    def generate_DuDxlp
      write_with_log("DuDxlp.c_code") do |io|
        io.puts "LW_ERROR0(\"DuDxlp not defined\");"
      end
    end

  private 

    ##
    # It writes a vector saved as an array as 
    # `result__[j] = compj` into the given `io`
    def write_array(ary, io)
      ary.each_with_index do |el, i|
        io.puts "result__[#{i}] = #{el.subs(@dict)};"
      end 
    end

    ##
    # It writes the non-zero components of a sparse matrix as 
    # `result__[j] = compj` into the given `io`
    def write_matrix(name, mx, dict)
      write_with_log(name) do |io| 
        i = -1
        mx.each_value do |v|
          io.puts "result__[#{i += 1}] = #{v.subs(dict)};"
        end
      end
    end

    ##
    # It creates a file with the given name passing the
    # `io` buffer to the given block and printing a log message
    # to the console
    def write_with_log(name)
      log_report(name) do
        open("OCP_tmp/#{name}", "w") { |io| yield io }
      end
    end

    ##
    # It prints a log message to the console before executing the
    # given block and after. This is used for debug purposes
    def log_report(file)
      print "Rendering `#{file}'..." if @ocproblem.verbose
      yield
      puts "done!" if @ocproblem.verbose
    end
  end
end