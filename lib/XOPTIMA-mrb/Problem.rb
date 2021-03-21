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
  class OCProblem
    class DescriprionError < StandardError; end

    include ProblemHelper

    attr_accessor :verbose

    attr_reader :rhs
    attr_reader :states
    attr_reader :controls
    attr_reader :dependentStates
    attr_reader :meshFunctions
    attr_reader :independent
    attr_reader :left
    attr_reader :right
    attr_reader :mass_matrix

    attr_reader :generic
    attr_reader :initial
    attr_reader :final
    attr_reader :cyclic

    attr_reader :control_bounds

    attr_reader :lagrange
    attr_reader :mayer

    # Parameters: stuff that doesn't fit anywhere else
    # Params: optimization parameters
    # aux_params: model parameters
    attr_reader :parameters, :params, :aux_params
    attr_reader :num_threads
    attr_reader :max_iter
    attr_reader :max_step_iter
    attr_reader :max_accumulated_iter
    attr_reader :tolerance
    attr_reader :lambdas, :omegas
    attr_reader :post_names, :int_post_names
    attr_reader :user_functions, :user_map_functions
    attr_reader :state_guess

    attr_reader :mesh

    attr_reader :H
    attr_reader :B
    attr_reader :nu 
    attr_reader :eta 
    attr_reader :df_dx
    attr_reader :df_du
    attr_reader :df_dp
    attr_reader :dH_dx
    attr_reader :dH_du
    attr_reader :dH_dp
    attr_reader :dJ_dx, :dJ_dp, :dJ_du
    attr_reader :m, :dm_du
    attr_reader :P
    attr_reader :g, :jump
    attr_reader :dmayer_dx, :dmayer_dp

    attr_reader :sparse_mxs
    attr_reader :adjointBC



    def initialize(name)
      @name    = name
      @loaded  = false
      @verbose = false

      # Boundary conditions
      @generic = {}
      @initial = {} 
      @final   = {}
      @cyclic  = {}

      # Control bounds
      @control_bounds = []
      @optimizable_cb = []

      # Target
      @lagrange = 0
      @mayer    = 0

      # Multipliers
      @lambdas = []
      @omegas  = []

      # Parameters 
      @parameters = [] # Will contain all the non-specified parameters
      @params     = [] # Pvars
      @aux_params = {} # ?

      # Names
      @post_names     = []
      @int_post_names = []

      # User functions
      @user_functions     = []
      @user_map_functions = []

      # Processing info
      @num_threads          = 4
      @max_iter             = 300
      @max_step_iter        = 40
      @max_accumulated_iter = 800
      @tolerance            = 1e-09
    end

    def loadDynamicSystem(rhs:             [], 
                          states:          [], 
                          controls:        [], 
                          params:          [], # => Pvars
                          dependentStates: [],
                          meshFunctions:   [],
                          independent:     var(:t),
                          left:            nil, 
                          right:           nil,
                          mass_matrix:     nil)
      @loaded          = true
      @rhs             = rhs
      @states          = states 
      @controls        = controls 
      @params          = params
      @dependentStates = dependentStates
      @meshFunctions   = meshFunctions
      @independent     = independent
      @left            = left || var(:"#{@independent.name}_i")
      @right           = right || var(:"#{@independent.name}_f")
      @mass_matrix     = mass_matrix || Matrix.identity(states.size)

      @generator = FileGenerator.new(self)

      OCProblemChecker.check_loaded_problem(self)
    end

    # Set the initial, final, cyclic or generic boundary conditions.
    # * Initial conditions are of type `x(zeta_i) = x_i`
    # * Final conditions are of type `x(zeta_f) = x_f`
    # * Cyclic conditions are of type `x(zeta_i) = x(zeta_f)`
    # * Generic conditions are of type `f(x(zeta_i)) = 0 or f(x(zeta_f)) = 0`
    def addBoundaryConditions(generic: {}, initial: {}, final: {}, cyclic: {})
      @generic = generic
      @initial = initial 
      @final   = final
      @cyclic  = cyclic

      OCProblemChecker.check_bc(self)
      if @verbose 
        __display_bc @generic, :generic 
        __display_bc @initial, :initial
        __display_bc @final,   :final
        __display_bc @cyclic,  :cyclic
      end
    end

    # It adds a interval constraint on given control: `-min <= u <= +max`.
    # The constraint is implemented as penalty function, which needs a name and 
    # a scale.
    #
    # Defaul constraint bounds are -1 and +1.
    def addControlBound(control, 
                        controlType: "QUADRATIC", 
                        label:       nil, 
                        epsilon:     1e-3,
                        tolerance:   1e-3,
                        max:         +1,
                        min:         -1,
                        maxabs:     nil,
                        scale:       +1)
      max    = OCProblemChecker.convert_to_symbolic(max, :max, :addControlBound)
      min    = OCProblemChecker.convert_to_symbolic(min, :min, :addControlBound)
      maxabs = OCProblemChecker.convert_to_symbolic(maxabs, :maxabs, :addControlBound) if maxabs
      scale  = OCProblemChecker.convert_to_symbolic(scale, :scale, :addControlBound)

      cb = ControlBound.new(control, controlType, label, epsilon, tolerance, max, min, scale, maxabs)
      OCProblemChecker.check_control_bound(cb)
      warn "Control bound for #{control} already added" if @control_bounds.include? cb 

      @control_bounds << cb
    end

    # Map a user defined function with a known regularized function that is 
    # registered.
    # 
    # Known regularized function are function available in the Machatronix 
    # library.
    # 
    # The parameters are optional and must be the ones specified for each 
    # class.
    # 
    # The command calling sequence has some options below described:
    # 
    # Arguments:
    #  * func_name: name of function to be mapped
    # 
    #  * class: name of the class of regularized function
    # 
    #  * pars: hash of parameters equal to initial value for class set up. Es. {h => 1, epsilon => 2}
    # 
    def mapUserFunctionToRegularized(func_name, klass, pars: {})
      if f = RegularizedFunctions[klass]
        pars = pars.empty? ? f[:parameters] : pars
        uf_map = UserFunctionMap.new(func_name, klass, pars, f[:args])
        warn "User function map already defined for symbol #{func_name}" if @user_map_functions.include? uf_map 
        @user_map_functions << uf_map
      else 
        raise DescriprionError, "Unknown function class `#{klass}'"
      end
    end

    # Bolza formulation defines both Mayer and Lagrange targets of the Optimal 
    # Control Problem.
    # Mayer term is the scalar term in the OCP formulation.
    # Mayer term must depend on zeta independent variable calculated on initial 
    # and/or final boundary
    # (i.e. zeta_i or/and zeta_f)
    # .
    # Lagrange term is the integral target of the Optimal Control Problem and 
    # must depend on zeta independent variable
    # 
    # Arguments:
    #  * mayer: algebraic expression of mayer term
    #  * lagrange: algebraic expression of lagrange term
    # 
    def setTarget(lagrange: 0, mayer: 0)
      @lagrange = OCProblemChecker.convert_to_symbolic(lagrange, :lagrange, :setTarget)
      @mayer    = OCProblemChecker.convert_to_symbolic(mayer, :mayer, :setTarget)
      OCProblemChecker.check_target(self)
    end

    # The command generates the C++ files that are necessary to solve the 
    # Optimal Control Problem.
    # The command is based on a Ruby script that parse the Maple generated code 
    # and applies the necessary transformations
    # suitable for the Xoptima library.
    # 
    # Arguments:
    #  * language = {C++(default)}
    #  * controls_iterative = {true,false}, if the iterative solution of the 
    #  control has to be used.
    #  This is necessary for some problems when controls cannot be solved 
    #  explicitly. For now this parameter is set to true.
    # 
    # It generates the C code of the discretized BVP defined by generateBVP() 
    # command.
    # The command also extracts the constant parameters and automatically 
    # reoders the list of expressions provided with the addDefaultParameters() command
    # The reordering is necessary to build a consistent input file that 
    # evaluates the parameter assigments in the correct sequence.
    # 
    # Arguments:
    #  * codegenOptions = list of option to pass to CodeGeneration
    def generateOCProblem(language:           "C++", 
                          controls_iterative: true, 
                          parameters:         {}, 
                          mesh:               {}, 
                          state_guess:        {}, 
                          post_processing:    [], 
                          clean:              true,
                          codegenOptions:     [])
      raise DescriprionError, "Dynamic system not loaded for problem #{@name}" unless @loaded
      OCProblemChecker.check_state_guess(state_guess)
      @aux_params  = parameters  # Add check
      @state_guess = state_guess
      
      @states_i_f  = __states_i_f
      
      @mesh = mesh 

      @H     = __h_term
      @B     = __b_term

      @lambdas_i_f = __lambdas_i_f

      @nu    = __nu 
      @eta   = __eta 
      @P     = __generate_penalty
      @J     = @P
      @df_dx = __df_dx
      @df_du = __df_du
      @df_dp = __df_dp
      @dH_dx = __dH_dx
      @dH_du = __dH_du
      @dH_dp = __dH_dp
      @dJ_dx = __dJ_dx
      @dJ_du = __dJ_du
      @dJ_dp = __dJ_dp
      @m     = __m
      @dm_du = __dm_du 
      @bc    = __bc
      @dmayer_dx = __Dmayer_dx
      @dmayer_dp = __Dmayer_dp

      @adjointBC = __adjointBC
      @g    = __g 
      @jump = __jump
      __collect_parameters
      __sparse_mxs

      if @verbose
        __display_loaded_problem
        puts "\nH:   #{@H}",
          "B:   #{@B}",
          "nu:  #{@nu}",
          "eta: #{@eta}\n\n",
          "df/dx: #{@df_dx}\n\n",
          "df/du: #{@df_du}\n\n",
          "df/dp: #{@df_dp}\n\n",
          "dH/dx: #{@dH_dx}\n\n",
          "dH/du: #{@dH_du}\n\n",
          "dH/dp: #{@dH_dp}\n\n",
          "dJ/dx: #{@dJ_dx}\n\n",
          "dJ/du: #{@dJ_du}\n\n",
          "dJ/dp: #{@dJ_dp}\n\n",
          "m: #{@m}\n\n",
          "bc: #{@bc}\n\n",
          "adjointBC: #{@adjointBC}\n\n",
          "g: #{@g}\n\n",
          "jump: #{@jump}\n\n",
          "P: #{@P}\n",
          "optimizable cb: #{@optimizable_cb.map(&:control).join(", ")}\n\n",
          "states_i_f: #{@states_i_f}\n",
          "lambdas_i_f: #{@lambdas_i_f}\n\n"
      end
      
      @generator.render_files
      puts "\nGenerating problem" if @verbose
      Command.generate_problem(@name, clean)
      puts "Finished!" if @verbose
    end

  private

    # This class represents an interval constraint on given control: 
    # `-min <= u <= +max`.
    # The constraint is implemented as penalty function, which needs a name and 
    # a scale
    #
    # Defaul constraint bounds are -1 and +1.
    class ControlBound

      attr_reader :control, :controlType, :label, :epsilon, :tolerance, :max, :min, :scale
      
      def initialize(control, controlType, label, epsilon, tolerance, max, min, scale, maxabs = nil)
        @control     = control
        @controlType = controlType
        @label       = label || "#{control}Control"
        @epsilon     = epsilon
        @tolerance   = tolerance
        @scale       = scale
        if maxabs
          @max = maxabs
          @min = -maxabs
        else 
          @max = max 
          @min = min 
        end
      end

      def ==(other)
        if other.is_a? ControlBound
          return @control == other.control 
        end 
        false
      end

      def to_s
        [
          "control: #{@control}",
          "  type:    #{@controlType}",
          "  label:   #{@label}",
          "  epsilon: #{@epsilon}",
          "  max:     #{@max}",
          "  min:     #{@min}",
          "  scale:   #{@scale}"
        ].join "\n"
      end
    end

    class UserFunctionMap
      attr_reader :par_h, :klass, :namepars, :func, :args, :par_delta

      # For ERB template only
      alias :label :func
      def initialize(name, klass, pars, args)
        # DATA[:UserMapFunctions] = [
        #  {
        #    :par_h => "0.1",
        #    :class => "ClipIntervalWithErf",
        #    :namepars => [ "delta", "h" ],
        #    :func => "clip",
        #    :args => [ "x", "a", "b" ],
        #    :par_delta => "0.1",
        #  } 
        @par_h     = pars[:h] || 0
        @klass     = klass
        @namepars  = pars.keys.map! &:to_s
        @func      = name 
        @args      = args
        @par_delta = pars[:delta] || 0
      end

      def ==(other)
        if other.is_a? UserFunctionMap
          return self.func == other.func
        end
        false
      end

      def to_s
        [
          "func: #{@func}",
          "  class: #{@klass}",
          "  namepars: #{@namepars}",
          "  args: #{@args}",
          "  par_h: #{@par_h}",
          "  par_delta: #{@par_delta}"
        ].join "\n"
      end
    end

    def __display_bc(lst, type)
      lst.each_key do |v|
        puts "#{type}_#{v} : Enabled"
      end
    end

    def __display_loaded_problem 
      puts [
        "==========================<Problem>==========================",
        "rhs:             #{@rhs}",
        "states:          #{@states}",
        "dependentStates: #{@controls}",
        "meshFunctions:   #{@meshFunctions}",
        "independent:     #{@independent}",
        "left:            #{@left}",
        "right:           #{@right}",
        "parameters:      #{@parameters}",
        "mass_matrix:     #{@mass_matrix}",
        "==========================<Target >==========================",
        "lagrange: #{@lagrange}",
        "mayer:    #{@mayer}",
        "====================<Boundary Conditions>====================",
        "generic: #{@generic}",
        "initial: #{@initial}",
        "final:   #{@final}",
        "cyclic:  #{@cyclic}",
        "=======================<Control Bound>======================="
      ].join "\n"
      @control_bounds.each { |cb| puts cb}
      puts "====================<User Map Functions >===================="
      @user_map_functions.each { |umf| puts umf}
    end
    
  end
end
