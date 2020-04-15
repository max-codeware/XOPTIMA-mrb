require "SymDesc"
require "XOPTIMA-mrb"

include XOPTIMA

# Set to `:local' for customized behaviour
SYM_CONFIG[:var_scope] = :global 

# Symbolic variables used
x, y, z = var :x, :y, :z

problem = Problem.new("my_problem")

# Set to `true' to display the states of the problem description
problem.verbose = false

# Problem equations
eqs = []
# eqs << ...


# State variables
state_vars = []

# Controls
cvars = []

# Optimization parameters
opars = []

# Dynamic system loading
problem.loadDynamicSystem(equations: eqs, states: state_vars, controls: cvars)

# Boundary conditions
problem.addBoundaryConditions(generic: {}, initial: {}, final: {}, cyclic: {})

# Constraints on control
problem.addControlBound(...)

# Cost function: target
problem.setTarget(lagrange: ..., mayer: ...)

#Problem generation
problem.generateOCProblem(
  clean: false,
  ...
)
