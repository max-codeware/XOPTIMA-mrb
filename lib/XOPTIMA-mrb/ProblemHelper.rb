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
  
  ##
  # This module contains some helper routine used during
  # the file generations. These methods are not intended to
  # be used outside `FileGenerator` class
  module ProblemHelper

    def bvp_parameters
    	[]
    end

    def guess_parameters
    	[]
    end

    def bc_parameters
    	[]
    end

    def post_processing_parameters
    	[]
    end

    def user_function_parameters
    	[]
    end

    def continuation_parameters
    	[]
    end

    def constraint_parameters
    	[]
    end

    def constraints1D
    	[]
    end

    def constraints2D
    	[]
    end

    def bc_count
    	@generic.size + @initial.size + @final.size + @cyclic.size
    end

    def q_n_eqns
      1
    end

    def post_n_eqns
      0
    end

    def integrated_post_n_eqns
      0
    end

    def substitution_dict
      dict = {}

      # X__[]
      @states.each_with_index do |s, i|
        dict[s] = var :"X__[#{i}]"
      end

      # XL__[]
      size = @states_i_f.size
      @states_i_f[0...-size/2].each_with_index do |sl, i|
        dict[sl] = var :"XL__[#{i}]"
      end

      # XR__[]
      @states_i_f[(size/2)..-1].each_with_index do |sr, i|
        dict[sr] = var :"XR__[#{i}]"
      end

      # L__[]
      @lambdas.each_with_index do |l, i|
        dict[l] = var :"L__[#{i}]"
      end

      # LL__[]
      size = @lambdas_i_f.size
      @lambdas_i_f[0...-size/2].each_with_index do |ll, i|
        dict[ll] = var :"LL__[#{i}]"
      end

      # LR__[]
      @lambdas_i_f[(size/2)..-1].each_with_index do |lr, i|
        dict[lr] = var :"LR__[#{i}]"
      end
      
      # U__[]
      @controls.each_with_index do |c,i|
        dict[c] = var :"U__[#{i}]"
      end
      
      # OMEGA__[]
      @omegas.each_with_index do |o, i|
        dict[o] = var :"OMEGA__[#{i}]"
      end

      # P__[]
      @params.each_with_index do |p, i|
        dict[p] = var :"P__[#{i}]"
      end

      @nu.each_with_index do |n, i|
        dict[n] = var :"V__[#{i}]"
      end

      return dict
    end

  end
end