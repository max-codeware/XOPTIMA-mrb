require "SymDesc"
require_relative "../lib/XOPTIMA-mrb.rb"

include XOPTIMA

# Set to `:local' for customized behaviour
SymDesc::SYM_CONFIG[:var_scope] = :global 

# Symbolic variables used
x, v, t, f, t_f = var :x, :v, :t, :F, :t_f

problem = OCProblem.new("BangBangF")

# Set to `true' to display the states of the problem description
problem.verbose = true

# Problem equations
rhs = []
rhs << v[t]
rhs << f[t]

# Mass matrix 
# mass_matrix =  Matrix[[...], ...]


# State variables
state_vars = [ x[t], v[t] ]

# Controls
cvars = [ f[t] ]

# Optimization parameters
opars = []

# Dynamic system loading
problem.loadDynamicSystem(rhs: rhs, states: state_vars, controls: cvars, independent: t)

# Boundary conditions
problem.addBoundaryConditions(initial: {x => 0, v => 0}, final: {v => 0})

# Constraints on control
problem.addControlBound(f, controlType: "U_COS_LOGARITHMIC", maxabs: 1)

# Cost function: target
problem.setTarget(mayer: -x[t_f])

#Problem generation
problem.generateOCProblem(
  clean: false,
  mesh: { s0: 0, segments: [ {length: 1, n: 100}]},
  state_guess: {v => t * (1 - t)}
)
