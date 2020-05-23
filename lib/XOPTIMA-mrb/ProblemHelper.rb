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

    def sparse_mxs
      @sparse_mxs = [
        #__DgDxlp,
        #__DgDu,
        #__DjumpDxlp,
        __DbcDx,
        __DbcDp,
        __DadjointBCDx,
        __DadjointBCDp,
        __DHxDx,
        __DHxDp,
        __DHuDx,
        __DHuDp,
        __DHpDp,
        __Drhs_odeDx,
        __Drhs_odeDp,
        __Drhs_odeDu,
        __A_ode,
        __DetaDx,
        __DetaDp,
        __DnuDx,
        __DnuDp
      ]
    end

  end
end