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
      generate_ocp_rb
    end
    
    ##
    # Renders and generates the file `OCP.rb`
    def generate_ocp_rb
      print "Rendering `OCP.rb'..." if @problem.verbose
      
      # Loading templates and creating renders
      ocp_rb_render         = make_template_render(OCPrb, OCPNameSet)
      user_f_class_i_render = make_template_render(UserFunctionsCI, UserFCINameSet)

      # Rendering content of `DATA[:UserFunctionsClassInstances]`
      user_f_class_i = render_user_functions_ci(user_f_class_i_render)

      states_n = @problem.states.size

      # Some parameters used to render `OCP.rb`
      q_n_eqns    = 1
      post_n_eqns = 0
      integrated_post_n_eqns = 0
      dudxlp_nr = @problem.controls.size 
      dudxlp_nc = 2 * states_n + (@problem.params.size) # Is @problem.param correct?
      controls_n = @problem.controls.size
      
      # Rendering `OCP.rb`. Names used are the same
      # appearing in `OCP.rb.erb` and strictly in the same
      # order
      ocp_rb = ocp_rb_render.render(
        @problem.num_threads,

        @problem.max_iter,
        @problem.max_step_iter,
        @problem.max_accumulated_iter,
        @problem.tolerance,

        @problem.states.map(&:to_s), 
        @problem.lambdas.map { |l| l.to_var.to_s },
        @problem.controls.map { |c| c.to_var.to_s },
        @problem.params,
        @problem.omegas.map { |o| o.to_s },
        @problem.post_names,
        @problem.int_post_names,
        @problem.independent,
        
        @problem.bvp_parameters,
        @problem.guess_parameters,
        @problem.bc_parameters,
        @problem.post_processing_parameters,
        @problem.user_function_parameters, 
        @problem.continuation_parameters,
        @problem.constraint_parameters,

        @problem.parameters,

        @problem.aux_params,

        @problem.user_functions,
        @problem.user_map_functions,
        user_f_class_i,

        @problem.constraints1D,
        @problem.constraints2D,
        @problem.control_bounds,
        @problem.generic,
        @problem.initial,
        @problem.final,
        @problem.cyclic,

        q_n_eqns,
        @problem.controls.size,
        2 * states_n, # jump_n_eqns
        @problem.bc_count,
        2 * states_n, # adjointBC_n_eqns
        @problem.rhs.size,
        @problem.dH_dx.size,
        @problem.dH_du.size,
        @problem.dH_dp.size,
        @problem.eta.size,
        @problem.nu.size ,
        post_n_eqns,
        integrated_post_n_eqns,

        dudxlp_nr,
        dudxlp_nc,

        states_n, # x_guess_n_eqns
        states_n, # l_guess_n_eqns
        @problem.params.size, # p_guess_n_eqns
        0,  # node_check_n_eqns
        0,  # nodeCheckStrings
        [], # cell_check_n_eqns
        [], # cellCheckStrings
        0,  # pars_check_n_eqns
        [], # parsCheckStrings
        controls_n, # u_guess_n_eqns
        controls_n, # u_check_n_eqns
        0, # numContinuationStep
        @problem.sparse_mxs
      )
      open("OCP_tmp/OCP.rb", "w") { |io| io.puts ocp_rb }
      puts "done!" if @problem.verbose
    end
  end
end