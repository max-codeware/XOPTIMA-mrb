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
  class Problem
    class DescriprionError < StandardError; end

    attr_accessor :verbose

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

      # Target
      @lagrange = 0
      @mayer    = 0
    end

    def loadDynamicSystem(rhs:             [], 
                          states:          [], 
                          controls:        [], 
                          dependentStates: [],
                          meshFunctions:   [],
                          independent:     var(:t),
                          mass_matrix:     nil)
      @loaded          = true
      @rhs             = rhs
      @states          = states 
      @controls        = controls 
      @dependentStates = dependentStates
      @meshFunctions   = meshFunctions
      @independent     = independent
      @mass_matrix     = mass_matrix || __id_matrix(states.size)
    end

    # Set the initial, final, cyclic or generic boundary conditions.
    # * Initial conditions are of type `x(zeta_i) = x_i`
    # * Final conditions are of type `x(zeta_f) = x_f`
    # * Cyclic conditions are of type `x(zeta_i) = x(zeta_f)`
    # * Generic conditions are of type `f(x(zeta_i)) = 0 or f(x(zeta_f)) = 0`
    # If the command is called without arguments then default initial and final 
    # boundary conditions are set.
    # Alternatively the boundary condition can be specified providing a hash 
    # for initial, final, cyclic or generic.
    def addBoundaryConditions(generic: {}, initial: {}, final: {}, cyclic: {})
      @generic = generic
      @initial = initial 
      @final   = final
      @cyclic  = cyclic
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
                        epsilon:     1e-2,
                        max:         +1,
                        maxabs:      +1,
                        min:         -1,
                        scale:       +1)

      cb = ControlBound.new(control, controlType, label, epsilon, max, maxabs, min, scale)
      if @control_bounds.include? cb 
        warn "Control bound for #{control} already added"
      end 
      @control_bounds << cb
    end

    def setTarget(lagrange: 0, mayer: 0)
      @lagrange = lagrange
      @mayer    = mayer
    end

    def generateOCProblem(*arg, **argk)
      raise DescriprionError, "Dynamic system not loaded for problem #{@name}" unless @loaded
      if @verbose
        __display_loaded_problem
      end
      
      h = __h_term
      puts "", "H: #{h}"
      
      b = __b_term
      puts "B: #{b}"
    end

  private

    # This class represents an interval constraint on given control: 
    # `-min <= u <= +max`.
    # The constraint is implemented as penalty function, which needs a name and 
    # a scale
    #
    # Defaul constraint bounds are -1 and +1.
    class ControlBound

      attr_reader :control, :controlType, :label, :epsilon, :max, :maxabs, :min, :scale
      
      def initialize(control, controlType, label, epsilon, max, maxabs, min, scale)
        @control     = control
        @controlType = controlType
        @label       = label
        @epsilon     = epsilon
        @max         = max 
        @maxabs      = maxabs
        @min         = min 
        @scale       = scale
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
          "  maxabs:  #{@maxabs}",
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
        "mass_matrix:\n[#{@mass_matrix.map(&:to_s).join(",\n")}]",
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

    def __id_matrix(size)
      id = Array.new(size) do |i|
        row = Array.new(size) { |j| i == j ? 1 : 0 }
      end
    end

    def __h_term 
      h = 0
      @rhs.each_with_index { |f, i| h += var(:"lambda#{i+1}") * f }
      return h + @lagrange
    end

    def __b_term
      b = 0
      i = 1
      @final.each do |bj, vj| 
        b += (bj[var(:"#{@independent}_f")] - vj) * var(:"omega#{i}")
        i += 1
      end

      @initial.each do |bj, vj| 
        b += (bj[var(:"#{@independent}_i")] - vj) * var(:"omega#{i}")
        i += 1
      end

      @cyclic.each do |bj, vj| 
        b += (bj[var(:"#{@independent}_c")] - vj) * var(:"omega#{i}")
        i += 1
      end

      @generic.each do |bj, vj| 
        b += (bj[var(:"#{@independent}_g")] - vj) * var(:"omega#{i}")
        i += 1
      end
      return b + @mayer
    end 
  end
end
