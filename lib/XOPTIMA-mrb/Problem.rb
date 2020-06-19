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

    attr_reader :parameters, :params, :aux_params
    attr_reader :num_threads
    attr_reader :max_iter
    attr_reader :max_step_iter
    attr_reader :max_accumulated_iter
    attr_reader :tolerance
    attr_reader :lambdas, :omegas
    attr_reader :post_names, :int_post_names
    attr_reader :user_functions, :user_map_functions

    attr_reader :mesh

    attr_reader :A
    attr_reader :B
    attr_reader :nu 
    attr_reader :eta 
    attr_reader :df_dx
    attr_reader :df_du
    attr_reader :df_dp
    attr_reader :dH_dx
    attr_reader :dH_du
    attr_reader :dH_dp
    attr_reader :P

    attr_reader :sparse_mxs



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
      @parameters = []
      @params     = []
      @aux_params = []

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
                        controlType: "U_QUADRATIC", 
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

    def setTarget(lagrange: 0, mayer: 0)
      @lagrange = OCProblemChecker.convert_to_symbolic(lagrange, :lagrange, :setTarget)
      @mayer    = OCProblemChecker.convert_to_symbolic(mayer, :mayer, :setTarget)
      OCProblemChecker.check_target(self)
    end

    def generateOCProblem(parameters: {}, mesh: {}, state_guess: {}, clean: true)
      raise DescriprionError, "Dynamic system not loaded for problem #{@name}" unless @loaded

      @states_i_f  = __states_i_f
      puts @states_i_f.inspect
      
      @mesh = mesh 

      @H     = __h_term
      @B     = __b_term

      @lambdas_i_f = __lambdas_i_f

      @nu    = __nu 
      @eta   = __eta 
      @df_dx = __df_dx
      @df_du = __df_du
      @df_dp = __df_dp
      @dH_dx = __dH_dx
      @dH_du = __dH_du
      @dH_dp = __dH_dp
      @P     = __generate_penalty
      @bc    = __bc
      @DadjointBC = @states_i_f.map { |xj| @B.diff(xj) }
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
          "bc: #{@bc}\n\n",
          "DadjointBC: #{@DadjointBC}\n\n",
          "g: #{@g}\n\n",
          "jump: #{@jump}\n\n",
          "P: #{@P}\n",
          "optimizable cb: #{@optimizable_cb.map(&:control).join(", ")}\n\n",
          "states_i_f: #{@states_i_f}\n",
          "lambdas_i_f: #{@lambdas_i_f}\n"
      end
      
      @generator.render_files
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
    end

    
  end
end
