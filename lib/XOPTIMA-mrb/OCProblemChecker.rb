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

  # Helper module to perform the argument checks on the inputs of
  # a problem
  module OCProblemChecker
    class << self
    
      ##
      # It checks the input parameters of `Problem#loadDynamicSystem`
      def check_loaded_problem(problem)
      	m = "loadDynamicSystem"

        # `states` and `controls` must be array containing only
        # objects of type `SymDesc::DependentVar`
        for param in [:states, :controls]
          v = problem.send(param)
          assert(v, Array, param, m)
          assert_array_of(v, SymDesc::DependentVar, param)
        end
        
        # These parameters must be arrays containing symbolic expressions 
        # or objects that can be converted into symbolic ones
      	for param in [:rhs, :dependentStates, :meshFunctions]
      		v = problem.send(param)
      		assert(v, Array, param, m)
        	assert_symbolic_array(v, param)
        end

        # The independent variable and the left and right sides must be
        # only symbolic variables
        assert(problem.independent,     SymDesc::Variable, :independent, m, strict: true)
        assert(problem.left,            SymDesc::Variable, :left,        m, strict: true)
        assert(problem.right,           SymDesc::Variable, :right,       m, strict: true)
        
        # Check if `mass_matrix` is a `XOPTIMA::Matrix`
        assert(problem.mass_matrix, Matrix, :mass_matrix, m)
        
        # Check if the states and the controls are functions depending only on
        # the independent variable
        problem.states.each { |state| assert_dependency_only_on(state, :state, problem.independent) }
        problem.controls.each { |ctrl| assert_dependency_only_on(ctrl, :controls, problem.independent) }
        
        # Check empty intersection of controls and states
        if !((insct = problem.controls & problem.states).empty?)
          raise OCPError, "Functions #{insct.join(", ")} appears both in state vars and controls"
        end
      end

      ##
      # It checks the input parameters of `addBoundaryConditions`.
      # The boundary conditions must be saved on Hash tables having
      # as key a symbolic variable and as value a symblic expression or
      # an object convertible to a symbolic one. Boundary contdition names
      # must appear in states.
      def check_bc(problem)
      	m = "addBoundaryConditions"
        state_names = problem.states.map { |dv| dv.name }
      	for param in [:generic, :initial, :final, :cyclic]
      	  h = problem.send(param)
          assert(h, Hash, param, m)
          assert_symbolic_hash(h,param, state_names: state_names)
        end 
      end

      ##
      # It checks the types of a control bound object:
      # * control: must be a symbolic variable
      # * controlType: must be a string
      # * label: must be a string
      # * epsilon: must be a numeric value
      # * tolerance: must be a numeric value
      def check_control_bound(cb)
      	m = "addControlBound"
      	assert(cb.control,     SymDesc::Variable, :control,     m, strict: true)
      	assert(cb.controlType, String,            :controlType, m)
      	assert(cb.label,       String,            :label,       m)
      	assert(cb.epsilon,     Numeric,           :epsilon,     m)
        assert(cb.tolerance,   Numeric,           :tolerance,   m)
      end

      ##
      # It checks the lagrange and mayer targets acquired from `Problem#setTarget`.
      # They must be or symbolic expressions or numbers.
      def check_target(problem)
      	assert_with_block("Parameter `lagrange' of `setTarget' is not symbolic or numeric") do
      		problem.lagrange.is_symbolic? || problem.lagrange.is_a?(Numeric)
      	end
        # `lagrange` must depend on the independent var
        assert_dependency_only_on(problem.lagrange, :lagrange, problem.independent)

      	assert_with_block("Parameter `mayer' of `setTarget' is not symbolic or numeric") do
      		problem.mayer.is_symbolic? || problem.mayer.is_a?(Numeric)
        end
        # `mayer` must depend on the left side or the right
        assert_dependency_only_on(problem.mayer, :mayer, problem.left, problem.right)
      end

      def assert(a, type, param, met, strict: false)
        condition = strict ? a.class == type : a.is_a?(type)
        raise TypeError, 
          "Parameter `#{param}' of `#{met}' expets type #{type}, not #{a.class}" unless condition
      end

      def assert_symbolic_array(v, param)
      	begin 
      		Check.ensure_symbolic(v)
      	rescue => e 
      		raise TypeError, "Array of parameter `#{param}' is not fully convertible into a symbolic one"
      	end
      end

      def assert_array_of(v, type, param)
        v.each do |comp|
          raise TypeError, 
            "Array of parameter `#{param}' is expexted to be #{type}, not #{comp.type}" unless comp.is_a? type
        end
      end
      
      def assert_symbolic_hash(h, param, **kw)
        state_names = kw[:state_names]
        h.each do |key, value|
          if key.class != SymDesc::Variable || !(value.is_symbolic? || value.is_a?(Numeric) || !value.respond_to?(:to_symdesc))
            raise TypeError, "Hash of parameter `#{param}' is not in the format {Variable => (Symbolic | Numeric)}"
          end
          if state_names && !state_names.include?(key)
            raise OCPError, "Boundary condition variable `#{key}' doesn't belong to state vars (#{param})"
          end
          h[key] = value.symdescfy
        end
      end

      def assert_with_block(msg)
      	raise TypeError, msg unless yield
      end

      def assert_dependency_only_on(exp, met, *vars)
        dvs = exp.dependent_vars
        dvs.each do |dv|
          args = dv.args
          if args.size != 1 || !vars.include?(args.first)
            raise OCPError, "Dependent variables in `#{met}' must depend only on #{vars.join(" or ")}"
          end
        end
      end

      def convert_to_symbolic(v, param, m)
        begin 
          return v.symdescfy 
        rescue => e
          raise TypeError, "Parameter `#{param}' of `#{m}' cannot be converted into a symbolic object"
        end
      end
      
    end
  end

end