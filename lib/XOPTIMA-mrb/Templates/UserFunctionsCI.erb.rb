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

##
# This is the ERB template for generating the `user_f_class_i`
# list for the `OCP.erb` one. This template is rendered in
# `FileGeneratorHelper#render_user_functions_ci`. All the parameters
# passed to the render are in the corresponding order
# they appear here. 
# For any modification, update the render arguments
# and the list of names in `GeneratorHelper::OCPNameSet`. 
# The order of the names must be strictly observed to maintain
# consistency.
#
# Since this is not the main template, the indentation is different
# to produce the correct one in `OCP.rb`
XOPTIMA::UserFunctionsCI = <<T
{
	    :is_mesh_object => "true",
      :mapped => [],
      :namespace => "Mechatronix",
      :class => "Mechatronix#MeshStd",
      :instance => "*pMesh",
      :setup => <%=mesh%>,
      :header => "#include <MechatronixCore/MechatronixCore.hh>",
    },
T