# Copyright (c) 2020-2021, Massimiliano Dal Mas
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

  if ENGINE.ruby?
    require "erb"
  end

  class FileGenerator

    include GeneratorHelper
    @@wrules = {}

    class Wrule
      attr_reader :mode, :rule
      def initialize(mode, rule)
        @mode = mode
        @rule = rule
      end
    end

    def self.define_file(filename, mode: :custom, **opt, &rule)
      raise ArgumentError, 
          "Unrecognised writing mode #{mode} (accepted: :vec, :matrix, :custom)" unless [:vec, :matrix, :custom].include? mode
      warn "Overwriting rule for file '#{filename}´" if @@wrules.has_key?(filename)
      if mode != :custom
        if !opt.has_key? :variable
          raise ArgumentError, "Missing variable option for file rule '#{filename}`"
        end
        rule = opt[:variable]
      end
      @@wrules[filename] = Wrule.new(mode, rule)
    end

    # It initializes the instance saving the `ocproblem`
    # description passes as argument.
    # It also creates a directory named `OCP_tmp` where all
    # the generated files are placed.
    def initialize(ocproblem)
      @ocproblem = ocproblem
      Dir.mkdir("OCP_tmp") unless Dir.exist? "OCP_tmp"
    end

    def render_files
      @dict = @ocproblem.substitution_dict
      generate_ocp_rb
      generate_sparse_mx_files

      @@wrules.each do |file, wrule|
        __write_with_log("#{file}.c_code") do |io|
          case wrule.mode
          when :custom
            instance_exec(io, &wrule.rule)
          when :vec
            __write_array(@ocproblem.instance_variable_get(:"@#{wrule.rule}"), io)
          when :matrix
            warn "Unhandled matrix writing for #{file}"
          end
        end
      end
    end

    ##
    # It renders and generates the file `OCP.rb`
    def generate_ocp_rb
      __log_report("OCP.rb") do
      
        # Loading templates and creating renders
        ocp_rb_render         = make_template_render(OCPrb, OCPNameSet)
        user_f_class_i_render = make_template_render(UserFunctionsCI, UserFCINameSet)

        # Rendering content of `DATA[:UserFunctionsClassInstances]`
        user_f_class_i = render_user_functions_ci(user_f_class_i_render)
      
        # Rendering `OCP.rb'
        ocp_rb = ocp_rb_render.render(@ocproblem, user_f_class_i)

        open("OCP_tmp/OCP.rb", "w") { |io| io.puts ocp_rb }
      end
    end

    ##
    # It generates all the files of the sparse matrices
    def generate_sparse_mx_files
      @ocproblem.sparse_mxs.each do |mx|
        __write_matrix("#{mx.label}.c_code", mx, @dict)
      end
    end

  private

    ##
    # It writes a vector saved as an array as 
    # `result__[j] = compj` into the given `io`
    def __write_array(ary, io)
      ary.each_with_index do |el, i|
        io.puts "result__[#{i}] = #{el.subs(@dict)};"
      end 
    end

    ##
    # It writes the non-zero components of a sparse matrix as 
    # `result__[j] = compj` into the given `io`
    def __write_matrix(name, mx, dict)
      __write_with_log(name) do |io| 
        i = -1
        mx.each_value do |v|
          io.puts "result__[#{i += 1}] = #{v.subs(dict)};"
        end
      end
    end

    ##
    # It creates a file with the given name passing the
    # `io` buffer to the given block and printing a log message
    # to the console
    def __write_with_log(name)
      __log_report(name) do
        open("OCP_tmp/#{name}", "w") { |io| yield io }
      end
    end

    ##
    # It prints a log message to the console before executing the
    # given block and after. This is used for debug purposes
    def __log_report(file)
      print "Rendering `#{file}'..." if @ocproblem.verbose
      yield
      puts "done!" if @ocproblem.verbose
    end


  end

end







