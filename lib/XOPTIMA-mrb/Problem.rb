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
    attr_reader :parameters


    def initialize(name)
      @name    = name
      @loaded  = false
      @verbose = false

      # Boundary conditions
      @generic = {}
      @initial = {} 
      @final   = {}
      @cyclic  = {}

      # Control bound
      @control_bounds = []
      @optimizable_cb = []

      # Target
      @lagrange = 0
      @mayer    = 0

      # Parameters 
      @parameters = []
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
      @H     = __h_term
      @B     = __b_term
      @nu    = __nu 
      @eta   = __eta 
      @df_dx = __df_dx
      @df_du = __df_du
      @df_dp = __df_dp
      @P     = __generate_penalty
      __collect_parameters

      if @verbose
        __display_loaded_problem
        puts "\nH:   #{@H}"
        puts "B:   #{@B}"
        puts "nu:  #{@nu}"
        puts "eta: #{@eta}\n\n"
        puts "df/dx: #{@df_dx}\n\n"
        puts "df/du: #{@df_du}\n\n"
        puts "df/dp: #{@df_dp}\n\n"
        puts "P: #{@P}\n"
        puts "optimizable cb: #{@optimizable_cb.map(&:control).join(", ")}"
      end
      
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
