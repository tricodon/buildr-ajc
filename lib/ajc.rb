require 'buildr/core/project'
require 'buildr/core/common'
require 'buildr/core/compile'
require 'buildr/packaging/artifact'
require 'buildr/packaging'

module Buildr
  module Compiler
    class Ajc < Base

      REQUIRES = Buildr.struct(
        #:aspectj => "org.aspectj:aspectjrt:jar:1.6.9",
        #:aspectjlib => "org.aspectj:aspectjlib:jar:1.6.2",
        #:aspectjweaver => "org.aspectj:aspectjweaver:jar:1.6.9",
      	:aspectjtools => "org.aspectj:aspectjtools:jar:1.6.9"
      ) unless const_defined?('REQUIRES')

      Java.classpath << Buildr.artifacts(REQUIRES)

      OPTIONS = [:warnings, :debug, :deprecation, :source, :target, :lint, :other, :Xlint, :aspectpath, :verbose]
          
      specify :language=>:java, :target=>'classes', :target_ext=>'class', :packaging=>:jar

      attr_reader :project

      def initialize(project, options) #:nodoc:
        super
        @project = project
      end

      def compile(sources, target, dependencies) #:nodoc:
        return if Buildr.application.options.dryrun

        info "options: #{options.inspect}"
        info "sources: #{sources.inspect}"
        info "dependencies: #{dependencies}"

        options[:source] ||= "1.6"

        cmd_args = []
        cmd_args << '-d' << File.expand_path(target)

        cmd_args << '-classpath' << dependencies.join(File::PATH_SEPARATOR) unless dependencies.empty?

        in_paths = sources.select { |source| File.directory?(source) }
        puts "inpath: #{in_paths.inspect}"
        cmd_args << '-inpath' << in_paths.join(File::PATH_SEPARATOR) unless in_paths.empty?

        cmd_args += javac_args

        cmd_args += files_from_sources(sources)

        aspect_path = []
        if options[:aspectpath] and not options[:aspectpath].empty?
          dependencies.each { |dep| options[:aspectpath].each { |regex| aspect_path<< dep if Regexp.new(regex).match dep}  }
        end
        aspect_path << options[:test_apspectpath] if options[:test_apspectpath]
        info "aspect path: #{aspect_path.inspect}"
        cmd_args << '-aspectpath' << aspect_path.join(File::PATH_SEPARATOR)

        Java.load # may be called by other extension before...so this has no effect

        messages = Java.org.aspectj.bridge.MessageHandler.new
        Java.org.aspectj.tools.ajc.Main.new.run(cmd_args.to_java(Java.java.lang.String), messages)

        messages.get_unmodifiable_list_view.each { |i| info i } if options[:verbose]
        messages.get_warnings.each { |w| warn w }
        messages.get_errors.each { |e| error e }
        
        fail 'Failed to compile, see errors above' if messages.get_errors.length > 0
      end

      private

      def javac_args #:nodoc:
        args = []
        args << '-nowarn' unless options[:warnings]
        args << '-verbose' if options[:verbose]
        args << '-g' if options[:debug]
        args << '-deprecation' if options[:deprecation]
        args << '-source' << options[:source].to_s if options[:source]
        args << '-target' << options[:target].to_s if options[:target]
        case options[:lint]
        when Array  then args << "-Xlint:#{options[:lint].join(',')}"
        when String then args << "-Xlint:#{options[:lint]}"
        when true   then args << '-Xlint'
        end
        args + Array(options[:other])
      end

    end
  end
end

Buildr::Compiler << Buildr::Compiler::Ajc


# call this to enable java ajc compiler
#
# ==options
# * :aspectpath - array of matching lib names (e.g. 'aspects' matches 'other-aspects-1.2.jar')
# * :verbose - true if any value
# * :debug - true if any value
# * :source - fix to 1.6
# * :deprecation - true if any value
# * :warnings - true if any value
# * :debug - true if any value
def compile_with_ajc(*opts)
  compile.using :ajc
  test.compile.using :ajc

  hash_opts ||= opts.last if Hash === opts.last
  puts "++++ #{hash_opts.inspect}"
  compile.using hash_opts

  hash_opts[:test_apspectpath] = compile.target.to_s
  test.compile.using hash_opts
end
