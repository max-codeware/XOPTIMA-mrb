# Copyright (c) 2021, Massimiliano Dal Mas
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

    @@methods    = {}
    @@accessors  = []
    @@sparse_mxs = {}
    @@wrules     = {}

    def self.define(name, &block)
      warn "Overwriting definition of '#{name}´" if @@methods.has_key?(name)
      attr_reader name
      @@methods[name] = block
    end

    def self.define_sparse(name, &block)
      warn "Overwriting sparse matrix definition of '#{name}´" if @@sparse_mxs.has_key?(name)
      @@sparse_mxs[name] = block
    end

    def self.define_accessor(name, auto: false, &block)
      warn "Overwriting definition of accessor method '#{name}´" if @@accessors.include?(name)
      define_method(name, block)
      @@accessors << name if auto
    end

    def compute_definitions
      @@methods.each do |name, method|
        value = instance_eval(&method)
        instance_variable_set(:"@#{name}", value)
        if verbose
          puts "#{name}: #{value}\n\n"
        end
      end

      @sparse_mxs = []
      @@sparse_mxs.each do |name, rule|
        puts "Computing #{name}"
        @sparse_mxs << self.instance_eval(&rule)
      end

      @@accessors.each { |name| send(name) }
    end

  end
end




