class COMMON_Build
  DATA = {}
  DATA[:numThread]            = <%=num_thread %>
  #--------------------------
  DATA[:max_iter]             = <%=max_iter %>
  DATA[:max_step_iter]        = <%=max_step_iter %>
  DATA[:max_accumulated_iter] = <%=max_accumulated_iter %>
  DATA[:tolerance]            = <%=tolerance%>
  #--------------------------
  DATA[:Xvars]        = <%=states%>
  DATA[:Lvars]        = <%=lambdas%>
  DATA[:Uvars]        = <%=controls%>
  DATA[:Pvars]        = <%=params%>
  DATA[:OMEGAvars]    = <%=omega_vars%>
  DATA[:POSTnames]    = <%=post_names%>
  DATA[:INTPOSTnames] = <%=int_post_names%>
  DATA[:Qvars]        = <%=independent%>

  #--------------------------
  DATA[:bvp_parameters]             = <%=bvp_parameters%>
  DATA[:guess_parameters]           = <%=guess_parameters%>
  DATA[:bc_parameters]              = <%=bc_parameters%>
  DATA[:post_processing_parameters] = <%=post_processing_parameters%>
  DATA[:user_function_parameters]   = <%=user_function_parameters%>
  DATA[:continuation_parameters]    = <%=continuation_parameters%>
  DATA[:constraint_parameters]      = <%=constraint_parameters%>

  #--------------------------
  DATA[:ModelParameters] = <%=parameters%>

  #--------------------------
  DATA[:AuxiliaryParameters] = <%=aux_params%>

  #--------------------------
  DATA[:UserFunctions]    = <%=user_functions%>
  DATA[:UserMapFunctions] = <%=user_map_functions%>
  DATA[:UserFunctionsClassInstances] = [
  <% for ufci in user_f_class_i %>
    <%=ufci%>
  <% end %>
  ]

  #--------------------------
  DATA[:Constraint1D] = <%=constraint1D%>
  DATA[:Constraint2D] = <%=constraint2D%>
  DATA[:ConstraintU ] = [
  <% for cb in control_bounds %>
    {
      :min       => "<%=cb.min%>",
      :max       => "<%=cb.max%>",
      :epsilon   => "<%=cb.epsilon%>",
      :type      => "<%=cb.type%>",
      :name      => "<%=cb.label%>",
      :tolerance => "<%=cb.tolerance%>",
      :class     => "PenaltyBarrierU",        #!!!
      :u         => "<%=cb.control[independent]%>",
      :scale     => "<%=cb.scale%>"
    },
  <% end %>
  ]
  DATA[:Bc] = [
  <% for name, value in generic%>
    {
      :name  => "initial_<%=name%>",
      :name1 => "initial_<%=name%>",
      :value => "<%=value%>"
    },
  <% end %>
  <% for name, value in initial%>
    {
      :name  => "initial_<%=name%>",
      :name1 => "initial_<%=name%>",
      :value => "<%=value%>"
    },
  <% end %>
  <% for name, value in final%>
    {
      :name  => "final_<%=name%>",
      :name1 => "final_<%=name%>",
      :value => "<%=value%>"
    },
  <% for name, value in cyclic%>
    {
      :name  => "initial_<%=name%>",
      :name1 => "initial_<%=name%>",
      :value => "<%=value%>"
    },
  <% end %>
  ]
  DATA[:q_n_eqns]               = <%=q_n_eqns%>
  DATA[:u_n_eqns]               = <%=controls_size%>
  DATA[:g_n_eqns]               = <%=control_bounds_size%>
  DATA[:jump_n_eqns]            = <%=jump_n_eqns%>
  DATA[:bc_n_eqns]              = <%=bc_count%>
  DATA[:adjointBC_n_eqns]       = <%=adjointBC_n_eqns%>
  DATA[:rhs_ode_n_eqns]         = <%=rhs_size%>
  DATA[:Hx_n_eqns]              = <%=dH_dx_size%>
  DATA[:Hu_n_eqns]              = <%=hu_n_eqns%>
  DATA[:Hp_n_eqns]              = <%=hp_n_eqns%>
  DATA[:eta_n_eqns]             = <%=eta_size%>
  DATA[:nu_n_eqns]              = <%=nu_size%>
  DATA[:post_n_eqns]            = <%=post_n_eqns%>
  DATA[:integrated_post_n_eqns] = <%=integrated_post_n_eqns%>

  DATA[:DuDxlp] = {
    :n_rows  => <%=dudxlp_nr%>,
    :n_cols  => <%=dudxlp_nc%>,
  }

  DATA[:x_guess_n_eqns]    = <%=x_guess_n_eqns%>
  DATA[:l_guess_n_eqns]    = <%=l_guess_n_eqns%> 
  DATA[:p_guess_n_eqns]    = <%=p_guess_n_eqns%>
  DATA[:node_check_n_eqns] = <%=node_check_n_eqns%>
  DATA[:NodeCheckStrings]  = <%=nodeCheckStrings%>
  DATA[:cell_check_n_eqns] = <%=cell_check_n_eqns%>
  DATA[:CellCheckStrings]  = <%=cellCheckStrings%>
  DATA[:pars_check_n_eqns] = <%=pars_check_n_eqns%>
  DATA[:ParsCheckStrings]  = <%=parsCheckStrings%>
  DATA[:u_guess_n_eqns]    = <%=u_guess_n_eqns%>
  DATA[:u_check_n_eqns]    = <%=u_check_n_eqns%>

  DATA[:NumContinuationStep] = <%=numContinuationStep%>

  #--------------------------(ALIAS)
  DATA[:alias] = [
  <%# control_bounds already given%>
  <% for cb in control_bounds%>
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
  DATA[:alias_names] = [
  <%# control_bounds already given%>
  <% for bc in control_bounds %>
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