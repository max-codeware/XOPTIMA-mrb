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

##
# This is the ERB template for generating the file
# `OCP.rb`. This template is rendered in
# `FileGenerator#generate_ocp_rb`. The parameters
# passed to `ocp_render` are the `OCProblem` instance and 
# an array containing the definitions of `UserFunctionsClassInstances`. 
# For any modification, update `ocp_render.render` arguments
# and the list of names in `GeneratorHelper::OCPNameSet`.
XOPTIMA::OCPrb = <<T
<%states_n = ocp.states.size%>\
<%controls_n = ocp.controls.size%>\
class COMMON_Build
  DATA = {}
  DATA[:numThread]            = <%=ocp.num_threads%>
  #--------------------------
  DATA[:max_iter]             = <%=ocp.max_iter%>
  DATA[:max_step_iter]        = <%=ocp.max_step_iter%>
  DATA[:max_accumulated_iter] = <%=ocp.max_accumulated_iter%>
  DATA[:tolerance]            = <%=ocp.tolerance%>
  #--------------------------
  DATA[:Xvars]        = <%=ocp.states.map { |s| s.to_var.to_s}%>
  DATA[:Lvars]        = <%=ocp.lambdas.map { |l| l.to_var.to_s }%>
  DATA[:Uvars]        = <%=ocp.controls.map { |c| c.to_var.to_s }%>
  DATA[:Pvars]        = <%=ocp.params%>
  DATA[:OMEGAvars]    = <%=ocp.omegas.map(&:to_s)%>
  DATA[:POSTnames]    = <%=ocp.post_names%>
  DATA[:INTPOSTnames] = <%=ocp.int_post_names%>
  DATA[:Qvars]        = "<%=ocp.independent%>"

  #--------------------------
  DATA[:bvp_parameters]             = <%=ocp.bvp_parameters%>
  DATA[:guess_parameters]           = <%=ocp.guess_parameters%>
  DATA[:bc_parameters]              = <%=ocp.bc_parameters%>
  DATA[:post_processing_parameters] = <%=ocp.post_processing_parameters%>
  DATA[:user_function_parameters]   = <%=ocp.user_function_parameters%>
  DATA[:continuation_parameters]    = <%=ocp.continuation_parameters%>
  DATA[:constraint_parameters]      = <%=ocp.constraint_parameters%>

  #--------------------------
  DATA[:ModelParameters] = <%=ocp.parameters%>

  #--------------------------
  DATA[:AuxiliaryParameters] = <%=ocp.aux_params%>

  #--------------------------
  DATA[:UserFunctions]    = <%=ocp.user_functions%>
  DATA[:UserMapFunctions] = <%=ocp.user_map_functions%>
  DATA[:UserFunctionsClassInstances] = [
  <% for ufci in user_f_class_i %>
    <%=ufci%>\
  <% end %>
  ]

  #--------------------------
  DATA[:Constraint1D] = <%=ocp.constraints1D%>
  DATA[:Constraint2D] = <%=ocp.constraints2D%>
  DATA[:ConstraintU ] = [
  <% for cb in ocp.control_bounds %>
    {
      :min       => "<%=cb.min%>",
      :max       => "<%=cb.max%>",
      :epsilon   => "<%=cb.epsilon%>",
      :type      => "<%=cb.controlType%>",
      :name      => "<%=cb.label%>",
      :tolerance => "<%=cb.tolerance%>",
      :class     => "PenaltyBarrierU",
      :u         => "<%=cb.control[ocp.independent]%>",
      :scale     => "<%=cb.scale%>"
    },
  <% end %>
  ]
  DATA[:Bc] = [
  <% for name, value in ocp.generic%>
    {
      :name  => "initial_<%=name%>",
      :name1 => "initial_<%=name%>",
      :value => "<%=value%>"
    },
  <% end %>\
  <% for name, value in ocp.initial%>
    {
      :name  => "initial_<%=name%>",
      :name1 => "initial_<%=name%>",
      :value => "<%=value%>"
    },
  <% end %>\
  <% for name, value in ocp.final%>
    {
      :name  => "final_<%=name%>",
      :name1 => "final_<%=name%>",
      :value => "<%=value%>"
    },
  <% end %>\
  <% for name, value in ocp.cyclic%>
    {
      :name  => "initial_<%=name%>",
      :name1 => "initial_<%=name%>",
      :value => "<%=value%>"
    },
  <% end %>
  ]
  DATA[:q_n_eqns]               = <%=ocp.q_n_eqns%>
  DATA[:u_n_eqns]               = <%=controls_n%>
  DATA[:g_n_eqns]               = <%=controls_n%>
  DATA[:jump_n_eqns]            = <%=2 * states_n%>
  DATA[:bc_n_eqns]              = <%=ocp.bc_count%>
  DATA[:adjointBC_n_eqns]       = <%=2 * states_n%>
  DATA[:rhs_ode_n_eqns]         = <%=ocp.rhs.size%>
  DATA[:Hx_n_eqns]              = <%=ocp.dH_dx.size%>
  DATA[:Hu_n_eqns]              = <%=ocp.dH_du.size%>
  DATA[:Hp_n_eqns]              = <%=ocp.dH_dp.size%>
  DATA[:eta_n_eqns]             = <%=ocp.eta.size%>
  DATA[:nu_n_eqns]              = <%=ocp.nu.size%>
  DATA[:post_n_eqns]            = <%=ocp.post_n_eqns%>
  DATA[:integrated_post_n_eqns] = <%=ocp.integrated_post_n_eqns%>

  DATA[:DuDxlp] = {
    :n_rows  => <%=controls_n%>,
    :n_cols  => <%=2 * states_n + (ocp.params.size)%>,
  }

  DATA[:x_guess_n_eqns]    = <%=states_n%>
  DATA[:l_guess_n_eqns]    = <%=states_n%> 
  DATA[:p_guess_n_eqns]    = <%=ocp.params.size%>
  DATA[:node_check_n_eqns] = <%=0%>
  DATA[:NodeCheckStrings]  = <%=[]%>
  DATA[:cell_check_n_eqns] = <%=0%>
  DATA[:CellCheckStrings]  = <%=[]%>
  DATA[:pars_check_n_eqns] = <%=0%>
  DATA[:ParsCheckStrings]  = <%=[]%>
  DATA[:u_guess_n_eqns]    = <%=controls_n%>
  DATA[:u_check_n_eqns]    = <%=controls_n%>

  DATA[:NumContinuationStep] = <%=0%>

  #--------------------------(ALIAS)
  DATA[:alias] = [\
  <% for cb in ocp.control_bounds%>
    "#define ALIAS_<%=cb.label%>_D_3(__t1, __t2, __t3) <%=cb.label%>.D_3( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_2(__t1, __t2, __t3) <%=cb.label%>.D_2( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_1(__t1, __t2, __t3) <%=cb.label%>.D_1( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_3_3(__t1, __t2, __t3) <%=cb.label%>.D_3_3( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_2_3(__t1, __t2, __t3) <%=cb.label%>.D_2_3( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_2_2(__t1, __t2, __t3) <%=cb.label%>.D_2_2( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_1_3(__t1, __t2, __t3) <%=cb.label%>.D_1_3( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_1_2(__t1, __t2, __t3) <%=cb.label%>.D_1_2( __t1, __t2, __t3)",
    "#define ALIAS_<%=cb.label%>_D_1_1(__t1, __t2, __t3) <%=cb.label%>.D_1_1( __t1, __t2, __t3)",
  <% end %>
  ]
  DATA[:alias_names] = [\
  <% for bc in ocp.control_bounds %>
    "<%=bc.label%>_D_3",
    "<%=bc.label%>_D_2",
    "<%=bc.label%>_D_1",
    "<%=bc.label%>_D_3_3",
    "<%=bc.label%>_D_2_3",
    "<%=bc.label%>_D_2_2",
    "<%=bc.label%>_D_1_3",
    "<%=bc.label%>_D_1_2",
    "<%=bc.label%>_D_1_1",
  <% end %>
  ]

end

<% for sparse_mx in ocp.sparse_mxs %>
  $SparseMatrix_<%=sparse_mx.label%> = {
    :n_rows  => <%=sparse_mx.rows%>,
    :n_cols  => <%=sparse_mx.cols%>,
    :nnz     => <%=sparse_mx.nnz%>,
    :pattern => <%=sparse_mx.pattern%>
  }
<% end %>
T