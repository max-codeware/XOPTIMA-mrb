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
  module Check
    class << self
      def ensure_symbolic(o) 
        case o 
        when Array, Matrix 
        	o.map! do |obj|
        	  begin 
        	  	obj.symdescfy 
        	  rescue => e 
        	  	raise ArgumentError, "#{o.class} is not fully convertible into a symbolic one"
        	  end
        	end	            
        else
        	begin 
        	  o.symdescfy 
        	rescue => e 
        	  raise ArgumentError, "#{o.class} is not fully convertible into a symbolic one"
        	end
        end
      end

      def matrix_product(m, b)
        case b 
        when Array 
        	if m.columns != b.size 
        		raise ArgumentError, "Inconsistent vector size for matrix product"
        	end 
        when Matrix 
        	if m.columns != b.columns 
        		raise ArgumentError, "Inconsistent matrix size for matrix product"
        	end 
        end
      end

      def not_nil(value)
        raise RuntimeError, "(Nil detected)" if value.nil?
      end
    end
  end
end