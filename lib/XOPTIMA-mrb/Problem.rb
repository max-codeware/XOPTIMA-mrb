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

    def init(name)
      @name = name
      @loaded = false
      @verbose = false

      # Boundaru conditions
      @generic = {}
      @initial = {} 
      @final   = {}
      @cyclic  = {}

      # Control bound
      @control_bounds = []
    end

    def loadDynamicSystem(equations:       [], 
                          states:          [], 
                          controls:        [], 
                          dependentStates: [],
                          meshFunctions:   [])
      @loaded          = true
      @equations       = equations
      @states          = states 
      @controls        = controls 
      @dependentStates = dependentStates
      @meshFunctions   = meshFunctions
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

    def setTarget(lagrange = 0, mayer = 0)
    end

    def generateOCProblem()
      raise DescriprionError, "Dynamic system not loaded for problem #{@name}" unless @loaded
    end

  private:

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
    end

    def __display_bc(lst, type)
      lst.each_key do |v|
        puts "#{type}_#{v} : Enabled"
      end
    end
  end
end
