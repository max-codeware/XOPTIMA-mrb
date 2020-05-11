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

  module OCProblemChecker
    class << self
    
      def check_loaded_problem(problem)
      	m = "loadDynamicSystem"

      	for param in [:rhs, :states, :controls, :dependentStates, :meshFunctions]
      		v = problem.send(param)
      		assert(v, Array, param, m)
        	assert_symbolic_array(v, param)
        end

        assert(problem.independent,     SymDesc::Variable, :independent, m, strict: true)
        assert(problem.left,            SymDesc::Variable, :left,        m, strict: true)
        assert(problem.right,           SymDesc::Variable, :right,       m, strict: true)

        assert(problem.mass_matrix, Matrix, :mass_matrix, m)

      end

      def check_bc(problem)
      	m = "addBoundaryConditions"
      	for param in [:generic, :initial, :final, :cyclic]
      	  h = problem.send(param)
          assert(h, Hash, param, m)
          assert_symbolic_hash(h,param)
        end 
      end

      def check_control_bound(cb)
      	m = "addControlBound"
      	assert(cb.control,     SymDesc::Variable, :control,     m, strict: true)
      	assert(cb.controlType, String,            :controlType, m)
      	assert(cb.label,       String,            :label,       m)
      	assert(cb.epsilon,     Numeric,           :epsilon,     m)
        assert(cb.max,         Numeric,           :max,         m)
        assert(cb.min,         Numeric,           :min,         m)
        assert(cb.scale,       Numeric,           :scale,       m)
      end

      def check_target(problem)
      	assert_with_block("Parameter `lagrange' of `setTarget' is not symbolic or numeric") do
      		problem.lagrange.is_symbolic? || problem.lagrange.is_a?(Numeric)
      	end
      	assert_with_block("Parameter `mayer' of `setTarget' is not symbolic or numeric") do
      		problem.mayer.is_symbolic? || problem.mayer.is_a?(Numeric)
      	end
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

      def assert_symbolic_hash(h, param)
        h.each do |key, value|
          if key.class != SymDesc::Variable || !(value.is_symbolic? || value.is_a?(Numeric))
            raise TypeError, "Hash of parameter `#{param}' is not in the format {Variable => (Symbolic | Numeric)}"
          end
        end
      end

      def assert_with_block(msg)
      	raise TypeError, msg unless yield
      end

    private 
    end
  end

end