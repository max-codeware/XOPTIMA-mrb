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

	class OCPError < StandardError; end

	[
		"./XOPTIMA-mrb/version.rb",
		"./XOPTIMA-mrb/Problem",
		"./XOPTIMA-mrb/ProblemHelper.rb",
		"./XOPTIMA-mrb/OCProblem.rb",
		"./XOPTIMA-mrb/ProblemRules.rb",
		"./XOPTIMA-mrb/Matrix.rb",
		"./XOPTIMA-mrb/Check.rb",
		"./XOPTIMA-mrb/OCProblemChecker.rb",
		"./XOPTIMA-mrb/Generator/GeneratorHelper.rb",
		"./XOPTIMA-mrb/Generator/FileGenerator.rb",
		"./XOPTIMA-mrb/Generator/FileDefinition.rb",
		"./XOPTIMA-mrb/Templates/OCP.erb.rb",
		"./XOPTIMA-mrb/Templates/UserFunctionsCI.erb.rb",
		"./XOPTIMA-mrb/Overload/SymDesc.rb",
		"./XOPTIMA-mrb/Command/Command.rb",
		"./XOPTIMA-mrb/RegFunctions/RegularizedFunctions.rb"
	].each do |file|
    require_relative file
	end
  
end
