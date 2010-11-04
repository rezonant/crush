# encoding: utf-8

require 'readline'
require 'tempfile'
require 'spoon' if RubyEngine == 'jruby'

#require File.dirname(__FILE__) + '/../rbmodexcl/mrimodexcl'

begin 
	require File.dirname(__FILE__) + '/lexer.rb' 
rescue LoadError 
	# Do nothing
end 

require File.dirname(__FILE__) + '/hash_defaults.rb'
require File.dirname(__FILE__) + '/helper.rb'
require File.dirname(__FILE__) + '/term_codes.rb'
require File.dirname(__FILE__) + '/columnator.rb'
require File.dirname(__FILE__) + '/filter_list.rb' 

# Crush::Shell is used to create an interactive shell.  It is invoked by the crush binary.
module Crush
	class Shell
		attr_accessor :suppress_output
		# Set up the user's environment, including a pure binding into which
		# env.rb and commands.rb are mixed.
		def initialize()
			Signal.trap("WINCH") { winch }
			
			root = Crush::Dir.new('/')
			home = Crush::Dir.new(ENV['HOME']) if ENV['HOME']
			box = Crush::Box.new
			
			# Initialize the shell state
			
			@macros = Hash.new						# [r] A hash of pattern => substitution for simple command line macros
			@shell_name = 'crush'						# [a] used as the canonical shell name, can be changed for differentiation
			@config = Crush::Config.new					#     access to the configuration object
			@help = Crush::Help.new						#     provides the crush help system
			@path = [ "#{ENV['HOME']}/#{Crush::ConfigDir}/commands", 	# [a] path used to find shell extensions loaded with 'import' function
			          "#{::File.dirname(__FILE__)}/commands" ]
			@box = Crush::Box.new						#     a localhost Box object to avoid making a bunch of them
			@interactive = true
			
			# The instance variable @binding holds the Ruby binding 
			# object which is used when evaluating commands entered on
			# the command line. Crush would supply an instance binding
			# against a localhost Box object, so that code executed 
			# as if it were entered within a 
			# 'module Crush; class Box; ...; end; end;' context.
			#
			# I'm not sure why the Box class was chosen for this most
			# crucial of roles and cannot in good conscience allow crush
			# to suffer the same fault.
			#
			# In fact, by default crush uses what I call "pure" binding,
			# which actually uses an eigenclass 
			
			#@binding = @box.instance_eval "binding"				# [a] specifies the variable context for the shell. Be CAREFUL!
			bind_pure
			
			@prompt = @default_prompt = proc do |shell|
				if shell.indent_level > 0 or shell.quoted
					" " * @shell_name.length + "  " + "  " * (shell.indent_level == 0 ? 0 : shell.indent_level - 1)
				else
					v = "#@shell_name> "
					#w = wd.inspect
					#v = v + "\e[s\e[#{columns - v.length - w.length - 10}C" + Term::DimOn + Term::ForegroundCyan + w + Term::ForegroundDefault + Term::DimOff + 
					#	"\e[u"
				end
			end

			@columns_cache_time = 0
			@report_inspection = false
			@report_collections = :enumerate
			@options = {}
			@reporter = true
			@indent_level = 0
			@quoted = nil
			@wd = Crush::Dir.new(ENV['PWD']) if ENV['PWD']
			
			@@lastInstance = self
			self.execute "shell = crush = $CRUSH = Crush::Shell.lastInstance", :print => false
			@@lastInstance = nil
			$last_res = nil
			
			# Set up readline
			
			@config.load_history.each do |item|
				Readline::HISTORY.push(item)
			end

			Readline.basic_word_break_characters = ""
			Readline.completion_append_character = nil
			Readline.completion_proc = completion_proc

			eval "require '#{::File.dirname(__FILE__) + "/functions.rb"}'"
			
			# Read and execute the contents of ~/.crush/env.rb
			eval @config.load_env, @binding

			commands = @config.load_commands
			Crush::Dir.class_eval commands
			Array.class_eval commands
		end

		attr_accessor :shell_name
		attr_accessor :path
		attr_writer :prompt
		attr_accessor :binding
		attr_accessor :reporter
		attr_accessor :report_inspection
		attr_accessor :report_collections
		attr_reader :indent_level
		attr_reader :macros
		attr_reader :quoted
		attr_reader :wd
		attr_accessor :interactive
		attr_reader :help
		attr_accessor :columns_cache_time
		attr_accessor :options
		
	public
	
		def bind(obj)
			@binding = obj.instance_eval { binding }
			prepare_binding @binding
		end

		def prepare_binding(b)
			eval %q{
				shell = $CRUSH
				box = Crush::Box.new
				home = Crush::Dir.new(ENV['HOME'], box)
				root = Crush::Dir.new('/', box)
				binding
			}, b
		end
		
		# Introduce en empty context for interpreting
		# shell expressions. This action happens when
		# crush is first launched and is vital for the correct
		# operation of the 'import' function. Thus, it should generally
		# not be called by the user. However, if a non-pure
		# binding is temporarily required, bind_pure can 
		# be used to return to a purely bound shell where
		# 'import' functions as expected.
		def bind_pure
			name = ''
			cls = Class.new do
				name = self.to_s
				def to_s() 'main' end
				def inspect() 'main' end
			#	def class() Object end
			private
				def __pure__() true end
			end

			# We remove this from exception messages in the default reporter.
			# FIXME: Please someone find a better way!
			@binding_name = name		
			env = cls.new
			env.remove_method :get_binding if env.respond_to? :get_binding
			env.instance_eval "def get_binding; binding; end"
			@binding = env.get_binding
			prepare_binding @binding
		end
	
		def set_binding(v)
			@binding = v
		end	

		# True if the shell is using a "pure" binding for 
		# executing incoming command lines.
		def is_pure?
			return true
			s = eval('self', @binding)
			s.private_methods.member?(:__pure__) and s.send(:__pure__)
#			['', nil].member? eval('self', @binding).class.name
		end
		
		# Cause all elements of the given module to be sowed into
		# the global namespace. Thus, given the following module:
		#   crush> module Foo
		#            def bar; puts 'baz'; end;
		#          end
		# Calling 'import Foo' will allow any subsequent command lines
		# to make use of the 'bar' function without specifying the Foo
		# module:
		#   crush> '#{bar} is the same as #{Foo::bar}'
		#    => "baz is the same as baz"
		def bind_include(mod)
			s = eval "self", @binding
			s.instance_eval { extend mod }
		end

		def bind_uninclude(mod)
			Object.uninclude mod
		end
		
		# The winch() method is called when crush receives a SIGWINCH. This 
		# signal is typically sent when the terminal has been resized in some way.
		# For some terminals SIGWINCH is not sent. 
		# You can call this method manually if your column size doesn't update
		# after resizing the terminal. 
		# Note: this method does not actually update the terminal size information,
		# instead it merely invalidates the cached info crush has saved. The heavy
		# lifting occurs in self.columns()
		def winch()
			@columns_time = Time.utc(0)
			nil
		end
		
		# Define a new macro. In crush, macros are simply a combination of a regexp and a 
		# replacement string, which may contain the standard placeholders accepted by
		# String.sub. Adding a macro (patt, repl) is equivalent to post-processing the 
		# output (outp) with outp.gsub(patt, repl).
		def define_macro(pattern, replacement = nil)
			puts pattern.class
			if pattern.kind_of? Hash
				pattern.each { |k,v| puts "with #{k} and #{v}..."; macro(k,v) }
			else
				raise Exception.new 'Second parameter cannot be nil unless the first is a hash' if replacement.nil?
				return @macros[pattern].tap do
					@macros = Hash.new if @macros.nil?
					@macros[pattern] = replacement
				end
			end
		end
		
		def unset_macro(pattern)
			[ pattern, @macros.delete(pattern) ] unless @macros.nil?
		end
		
		def apply_macros(input)
			return input if @macros.nil?
			
			@macros.each { |pr| input = input.gsub *pr }
			input
		end
		
		def version()
			@help.version
		end
		
		def splash()
			@help.splash
		end
		
		def cd(dest = nil)
			dest ||= Crush::Dir.new(ENV['HOME'])
			dest = dest.to_s if dest.kind_of? Symbol
			dest = dir dest
			
			::Dir.chdir dest.full_path
			@wd = dest
		end

		def columns
			return @columns if @columns
			
			@columns_time, @columns_cache = Time.utc(0), 0 unless @columns_time
			
			cache_time = @columns_cache_time
			cache_time = 60 * 60 unless cache_time != 0
			
			if (Time.now - @columns_time) > @columns_cache_time
				@columns_time = Time.now
				
				begin
					if RUBY_ENGINE == 'jruby'
						Tempfile.open("cols") do |tf|
							Spoon.spawnp "bash", "-c", "stty size >#{tf.path} 2&>/dev/null"
							Process.wait
							@columns_cache = tf.read.split[1].to_i
						end
					else
						@columns_cache = `stty size`.split[1].to_i
					end
					
					ENV['COLUMNS'] = @columns_cache.to_s
				rescue ::Exception => e
					puts "caught exception #{e.class} -- #{e.message}"
					puts backtrace
				end
			end
				@columns_cache
		end
		
		attr_writer :columns
			
		def dir(dest)
			if dest.kind_of? Dir or dest.kind_of? File	# Already a file/dir object
			end

			if dest.kind_of? String
				if dest[0,1] == '/'				# Absolute paths
					return (::File.directory?(dest) ? Dir.new(dest) : File.new(dest)) 
				end

				return wd[dest] if dest.end_with? '/'
				return wd["#{dest}/"] if FileTest.directory?(wd.full_path + '/' + dest)
				return wd[dest] if FileTest.exist?(wd.full_path + '/' + dest)
				raise DoesNotExist.new "#{dest}"
			else
				dest
			end
		end
		
		def backtrace(e = $e)
			r = []
			e.backtrace.each do |t|
				r << "    #{::File.expand_path(t)}"
			end
			r.join("\n")
		end
		
		def ls(dest = ".", mode = nil)
			dest = wd if dest == "."
			dest = dir(dest)
			dest.ls mode
		end

		def help(topic = 'intro')
			line = $CRUSH_EXECUTABLE + ' -eval \$CRUSH.help_unpaged \\\'' + topic.to_s.gsub(/'/, '\\\'') + '\\\' | less -r'
			system line
		end
		
		def help_unpaged(topic = 'intro')
			@help.topic(topic)
			:sshh
		end
		
		def mv (from, to, verbose = false)
			from = Crush::File.new(from) if from.instance_of? String
			to = Crush::File.new(to) if to.instance_of? String
		end
	
		def bash(*args)
			system args.join(" ")
		end
		
		def ssh (host)
			bash :ssh, host
			:sshh
		end
	
		def clear()
			system 'clear'
			:sshh
		end
		
		def ri(topic)
			if topic.instance_of? Class
				topic = topic.name
			elsif topic.instance_of? Symbol
				topic = topic.to_s
			end
			
			bash "ri", topic
		end
		
		def prompt
			if @prompt.respond_to?(:call)
				begin
					@prompt.call(self)
				rescue
					puts " x> " + $!.to_s
					@prompt = @default_prompt
					retry
				end
			elsif
				@prompt
			end
		end
	
		def Shell.lastInstance()
			return @@lastInstance;
		end
		
		def last
			$last_res
		end
		
		def last!
			print_result last
			:sshh
		end
		
		# Run a single command.
		def execute(cmd, options = Hash.new)
			options.with_defaults!(:print => true)
			
			res = eval(cmd, @binding)
			$last_res = res
			eval("_ = $last_res", @binding)
			
			if cmd.strip[0,1] == '`'
				puts res.to_s
			else
				print_result res if @reporter and options[:print]
			end
		rescue ::SystemExit => e
			raise e		# let exit exceptions through
		rescue ::StandardError => e
			print_result e
			$e = e
		rescue Crush::Exception => e
			puts " x> #{e.class}: #{e.message}"
		rescue ::Exception => e
			return if e.class.to_s == 'Interrupt'
			
			print_result e
		end
		
		def exit_loop
			throw :crush_exit_loop
		end
		
		def run
			attempts, max = 0, 10
			catch :crush_exit_loop do
				begin
					if defined? RubyLex 
						run_rubylex
					else 
						run_readline
					end 
				rescue ::SystemExit
					return
				rescue ::Exception => e
					puts e.backtrace
					puts "$:-(=}      x> #{e.class} -- #{e.message}"
					if attempts < max
						attempts += 1
						redo
					end
				end
			end
			puts
			puts "goodbye!"
		end

		# Run the interactive shell using readline.
		def run_readline
			loop do
				cmd = Readline.readline(@prompt)

				finish if cmd.nil? or cmd == 'exit'
				next if cmd == ""
				Readline::HISTORY.push(cmd)

				execute(cmd)
			end
		end
		
		def expand(cmd)
			cmd = apply_macros cmd
			cmd = cmd.gsub(/λ/, ' lambda ')
			cmd = cmd.gsub(/"/, '\"').sub(/^\$ /, 'system "') + '";:sshh' if cmd.start_with? '$ '
				
			cmd 
		end

		# Run the interactive shell using RubyLex and readline. 
		def run_rubylex
			line = "" 
			cmd = "" 
			@lexer = RubyLex.new 
			@lexer.set_input(STDIN) do 
				@indent_level = @lexer.indent
				@quoted = @lexer.quoted
				begin
					cmd = Readline.readline(prompt())
					if cmd.nil?
						""
					else
						Readline::HISTORY.push cmd if cmd != ''
						expand(cmd) + "\n"
					end
				rescue ::Interrupt => e
					puts
					''
				end
			end 

			@lexer.each_top_level_statement do |cmd, i| 
				break if cmd.chop == 'exit' 
				execute cmd 
			end 

			finish
		end

		# Save history to ~/.crush/history when the shell exists.
		def finish
			@config.save_history(Readline::HISTORY.to_a)
			puts
			exit
		end

		# Nice printing of different return types, particularly Crush::SearchResults.
		def print_result(res)
			
			return if self.suppress_output or :sshh == res
			
			if @reporter.respond_to? :call
				return if print_results.call res
			end
			
			report res
		end

		def report(res)
			cols = columns - 10
			if res.kind_of? String
				s = Term::ForegroundYellow
				d = Term::ForegroundDefault
				puts " => #{s}\"#{res.gsub(/\n/, "\n#{d}#{Term::DimOn}:::::#{Term::DimOff}#{s}")}\"#{d}"
			elsif res.kind_of? Symbol
				puts " => :#{res.to_s}"
			elsif res.kind_of? Crush::ProcessSet
				pid_width = 0
				local = true
				res.each do |p| 
					pid_width = [pid_width, p.pid.to_s.length].max
					if p.box.to_s != 'localhost'
						local = false 
						break
					end
				end
				
				pid_width += 2
				
				res.each do |p|
					color = Term::ForegroundBlue
					end_color = Term::ForegroundDefault
					cmdline = p.cmdline
					dim = Term::DimOn
					end_dim = Term::DimOff
					
					if pid_width + cmdline.length - 1 > columns
						cmdline = "#{cmdline[0, columns - pid_width - 5]}#{color} ... #{end_color}"
					end
					
					if cmdline.include? ' '
						ccs = cmdline.split ' '
						cmdline = "#{ccs[0]} #{dim}#{ccs[1,ccs.length].join(' ')}#{end_dim}"
					end
					
					if local
						puts "#{color}#{p.pid.to_s}#{end_color}#{' ' * (pid_width - p.pid.to_s.length)}" +
								cmdline
					else
						puts "#{color}#{p.pid.to_s}#{end_color}#{' ' * (pid_width - p.pid.to_s.length)}" +
								cmdline
					end
				end
			elsif res.kind_of? Crush::SearchResults
				if res.entries.length == 0
					puts " => No results."
					return nil
				end
				
				widest = res.entries.map { |k| k.full_path.length }.max
				viewSize = cols - widest - 4 - "plus nnnn more matches ".length
				
				res.entries_with_lines.each do |entry, lines|
					print entry.full_path
					print ' ' * (widest - entry.full_path.length + 2)
					print "=> "
					fline = lines.first.strip
					print res.colorize(fline.head(viewSize - 3))
					print "..." if lines.first.strip.length > viewSize - 3
					if lines.size > 1
						print ' ' * (viewSize - [viewSize, fline.length].min) + 
								" (plus #{lines.size - 1} more matches)"
					end
					print "\n"
				end
				puts "#{res.entries.size} matching files with #{res.lines.size} matching lines"
			elsif res.kind_of? Crush::Exception
				print " x> "
				
				msg = prepare_exception_message(res.message)

				if res.kind_of? Crush::DoesNotExist
					puts "`#{msg}' does not exist (#{res.class})"
				elsif res.kind_of? Crush::NotAuthorized
					puts "not authorized; #{msg}  (#{res.class})"
				elsif res.kind_of? Crush::CrushdNotRunning
					puts "crushd is not running on remote host"
				elsif res.kind_of? Crush::FailedTransmit
					puts "an unrecognized status code was returned by crushd"
				elsif res.kind_of? Crush::BashFailed
					puts "-------"
					puts "    stderr:"
					puts "      #{msg.gsub(/\n/, "\n      ")}"
					puts "    -------"
					puts "    command returned an error code. stderr is printed above.  (#{res.class})"
					puts
				elsif res.kind_of? Crush::NameAlreadyExists
					puts "an entry named `#{msg}' already exists in the given directory  (#{res.class})"
				elsif res.kind_of? Crush::NameCannotContainSlash
					puts "name `#{msg}' cannot contain slash  (#{res.class})"
				elsif res.kind_of? Crush::NotADir
					puts "given destination `#{msg}' is not a directory  (#{res.class})"
				elsif res.kind_of? Crush::BadAccessSpecifier
					puts "invalid access specifier `#{msg}'  (#{res.class})"
				else 
					puts  "#{res.class}: #{msg}"
				end
	
			elsif res.kind_of? ::StandardError
				msg = prepare_exception_message(res.message)
				puts " x> #{res.class}: #{msg}"
			elsif res.kind_of? ::Exception
				msg = prepare_exception_message(res.message)
				puts " x> #{res.class}: #{msg}"
				puts backtrace res
			elsif res.kind_of? ::Hash
				key_column = 0
				res_str = res.map do |k,v|
					[k.to_s, v.to_s]
				end
				
				#puts res_str.inspect
				res_str.each { |k,v| key_column = [key_column, k.length].max } \
					   .each { |k,v| puts k + (' ' * (key_column - k.length)) + ' => ' + v }
				
			elsif res.respond_to? :each
				if @report_collections == :to_s
					puts " => #{res}"
				elsif @report_collections == :inspect
					puts " => #{res.inspect}"
				else #elsif @report_collections == :enumerate
					counts = {}
					total = 0
					res.each do |item|
						puts item
						counts[item.class] ||= 0
						counts[item.class] += 1
						total += 1
					end
					if counts == {}
						es = "(empty set)"
						es = res.empty_set_label if res.respond_to? :empty_set_label

						puts " => #{es} in #{res.inspect}"
					else
						count_s = counts.map do |klass, count|
							"#{count} x #{klass}"
						end.join(', ')

						min_items = (self.options[:report_collection_count_min_items] or 5)
						puts " => #{count_s}" unless res.duck_query :sshh_count? or (counts.length == 1 and total < min_items)
					end
				end
			elsif res.nil?
				puts " => nil"
			else
				if @report_inspection
					puts " => #{res.inspect}"
				else
					puts " => #{res}"
				end
			end	
		end
	
		def prepare_exception_message(msg)
			msg.sub(/.*:[0-9]+:in `[A-Za-z*]+': /, '').gsub("#{@binding_name}::", '')
		end
	
		def path_parts(input)		# :nodoc:
			case input
			when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)([\[\/])(['"])([^\3]*)$/
				$~.to_a.slice(1, 4).push($~.pre_match)
			when /((?:@{1,2}|\$|)\w+(?:\[[^\]]+\])*)(\.)(\w*)$/
				$~.to_a.slice(1, 3).push($~.pre_match)
			when /((?:@{1,2}|\$|)\w+)$/
				$~.to_a.slice(1, 1).push(nil).push($~.pre_match)
			else
				[ nil, nil, nil ]
			end
		end

		def complete_method(receiver, dot, partial_name, pre)
			path = eval("#{receiver}.full_path", @binding) rescue nil
			box = eval("#{receiver}.box", @binding) rescue nil
			if path and box
				(box[path].methods - Object.methods).select do |e|
					e.match(/^#{Regexp.escape(partial_name)}/)
				end.map do |e|
					(pre || '') + receiver + dot + e
				end
			end
		end

		def complete_path(possible_var, accessor, quote, partial_path, pre)		# :nodoc:
			original_var, fixed_path = possible_var, ''
			if /^(.+\/)([^\/]*)$/ === partial_path
				fixed_path, partial_path = $~.captures
				possible_var += "['#{fixed_path}']"
			end
			full_path = eval("#{possible_var}.full_path", @binding) rescue nil
			box = eval("#{possible_var}.box", @binding) rescue nil
			if full_path and box
				Crush::Dir.new(full_path, box).entries.select do |e|
					e.name.match(/^#{Regexp.escape(partial_path)}/)
				end.map do |e|
					(pre || '') + original_var + accessor + quote + fixed_path + e.name + (e.dir? ? "/" : "")
				end
			end
		end

		def complete_variable(partial_name, pre)
			lvars = eval('local_variables', @binding)
			gvars = eval('global_variables', @binding)
			ivars = eval('instance_variables', @binding)
			(lvars + gvars + ivars).select do |e|
				e.match(/^#{Regexp.escape(partial_name)}/)
			end.map do |e|
				(pre || '') + e
			end
		end

		# Try to do tab completion on dir square brackets and slash accessors.
		#
		# Example:
		#
		# dir['subd    # presing tab here will produce dir['subdir/ if subdir exists
		# dir/'subd    # presing tab here will produce dir/'subdir/ if subdir exists
		#
		# This isn't that cool yet, because it can't do multiple levels of subdirs.
		# It does work remotely, though, which is pretty sweet.
		def completion_proc
			proc do |input|
				receiver, accessor, *rest = path_parts(input)
				if receiver
					case accessor
					when /^[\[\/]$/
						complete_path(receiver, accessor, *rest)
					when /^\.$/
						complete_method(receiver, accessor, *rest)
					when nil
						complete_variable(receiver, *rest)
					end
				end
			end
		end
	end
end
