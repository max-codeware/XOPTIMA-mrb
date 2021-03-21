require "SymDesc"
require_relative "../../lib/XOPTIMA-mrb.rb"

include XOPTIMA

# Set to `:local' for customized behaviour
SymDesc::SYM_CONFIG[:var_scope] = :global 

# Symbolic variables used
x, v, f, clip, minClip, maxClip, tau, t, vF, t_f, vFmax = 
  var :x, :v, :f, :clip, :minClip, :maxClip, :tau, :t, :vF, :t_f, :vFmax

problem = OCProblem.new("BangBangFclip")

# Set to `true' to display the states of the problem description
problem.verbose = true

# Problem equations
rhs = [
	v[t],
	clip[f[t], minClip, maxClip],
	vF[t] - 0 * (f[t] - clip[f[t], minClip, maxClip]) / tau
]

# Mass matrix 
# mass_matrix =  Matrix[[...], ...]

# State variables
state_vars = [x[t], v[t], f[t]]

# Controls
cvars = [ vF[t] ]

# Optimization parameters
opars = []

# Dynamic system loading
problem.loadDynamicSystem(rhs: rhs, states: state_vars, controls: cvars, independent: t)

# Boundary conditions
problem.addBoundaryConditions(initial: {x => 0, v => 0, f => 0}, final: {v => 0, f => 0})

# Constraints on control
problem.addControlBound(vF, label: "controlForce", maxabs: vFmax)

problem.mapUserFunctionToRegularized(clip, "ClipIntervalWithErf", pars: {h: 0.1, delta: 0.1})

# Cost function: target
problem.setTarget(mayer: -x[t_f])

#Problem generation
problem.generateOCProblem(
  clean: false,
  post_processing: [],
  parameters: {vFmax => 10, minClip => -1, maxClip => 1},
  mesh: { s0: 0, segments: [ {length: 0.1, n: 10}, {length: 0.4, n:40}, {length: 0.4, n: 40}, {length: 1, n: 10} ] },
  state_guess: {v => 1}
)

# Parametri => aggiunti a OCP.rb sotto ModelParameters
