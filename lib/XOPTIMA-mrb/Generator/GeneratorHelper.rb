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
  module GeneratorHelper

  	##
  	# This list contains all the names that appear
  	# in the `OCPrb` template in the same order without
  	# duplications. This order must be strictly observed,
  	# and any modification in the template names must be
  	# followed by an update of this list
    OCPNameSet = [
      :num_thread,

      :max_iter,
      :max_step_iter,
      :max_accumulated_iter,
      :tolerance,

      :states,
      :lambdas,
      :controls,
      :params,
      :omegas,
      :post_names,
      :int_post_names,
      :independent,

      :bvp_parameters,
      :guess_parameters,
      :bc_parameters,
      :post_processing_parameters,
      :user_function_parameters,
      :continuation_parameters,
      :constraint_parameters,

      :parameters,

      :aux_params,

      :user_functions,
      :user_map_functions,
      :user_f_class_i,

      :constraint1D,
      :constraint2D,
      :control_bounds,
      :generic,
      :initial,
      :final,
      :cyclic,

      :q_n_eqns,
      :controls_size,
      :jump_n_eqns,
      :bc_count,
      :adjointBC_n_eqns,
      :rhs_size,
      :dH_dx_size,
      :dH_du_size,
      :dH_dp_size,
      :eta_size,
      :nu_size,
      :post_n_eqns,
      :integrated_post_n_eqns,

      :dudxlp_nr,
      :dudxlp_nc,

      :x_guess_n_eqns,
      :l_guess_n_eqns,
      :p_guess_n_eqns,
      :node_check_n_eqns,
      :nodeCheckStrings,
      :cell_check_n_eqns,
      :cellCheckStrings,
      :pars_check_n_eqns,
      :parsCheckStrings,
      :u_guess_n_eqns,
      :u_check_n_eqns,
      :numContinuationStep,
      :sparse_mxs
    ]

    UserFCINameSet = [
    	:mesh
    ]

    ##
    # Creates a template render object with the
    # template in `file`. It's method `render`
    # accepts parameters stated in `name_set`.
    #
    # The extension `.erb` is automatically added to
    # the file name in `file`
    def make_template_render(template, name_set)
      erb = ERB.new(template, trim_mode: "<>")
      renderer = erb.def_class(Object, "render(#{name_set.join(",")})")
      return renderer.new
    end

    def render_user_functions_ci(render)
      [render.render(@problem.mesh)]
    end

  end
end