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

  	def initialize(ocproblem)
  		@ocproblem = ocproblem
      Dir.mkdir("OCP_tmp") unless Dir.exist? "OCP_tmp"
  	end

    def render_files
      @dict = @ocproblem.substitution_dict
      generate_ocp_rb
      generate_sparse_mx_files
      generate_precalculated
      generate_rhs_ode
      generate_checks
    end
    
    ##
    # Renders and generates the file `OCP.rb`
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
    # Generates all the files of the sparse matrices
    def generate_sparse_mx_files
      @ocproblem.sparse_mxs.each do |mx|
        write_matrix("#{mx.label}.c_code", mx, @dict)
      end
    end
    
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
        io << "result__ = #{@ocproblem.H.subs(@dict)}"
      end
    end

    def generate_rhs_ode
      write_with_log("rhs_ode.c_code") do |io|
        write_array(@ocproblem.rhs, io)
      end
    end

    def generate_checks
      write_with_log("cell_check.c_code") do |io|
      end

      write_with_log("node_check.c_code") do |io|
      end

      write_with_log("pars_check.c_code") do |io|
      end

      write_with_log("u_check.c_code") do |io|
      end
    end

    def generate_guess
      write_with_log("l_guess.c_code") do |io|
      end

      write_with_log("u_guess.c_code") do |io|
      end

      write_with_log("x_guess.c_code") do |io|
      end

      write_with_log("p_guess.c_code") do |io|
      end
    end

  private 

    def write_array(ary, io)
      ary.each_with_index do |el, i|
        io.puts "result__[#{i}] = #{el.subs(@dict)}"
      end 
    end

    def write_matrix(name, mx, dict)
      write_with_log(name) do |io| 
        i = -1
        mx.each_value do |v|
          io.puts "result__[#{i += 1}] = #{v.subs(dict)}"
        end
      end
    end

    def write_with_log(name)
      log_report(name) do
        open("OCP_tmp/#{name}", "w") { |io| yield io }
      end
    end

    def log_report(file)
      print "Rendering `#{file}'..." if @ocproblem.verbose
      yield
      puts "done!" if @ocproblem.verbose
    end
  end
end