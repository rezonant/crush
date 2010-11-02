require 'rubygems'

Infinity = 1.0/0
if /1.8.[0-9]+/ =~ RUBY_VERSION
	RubyEngine = 'ruby'
else
	RubyEngine = RUBY_ENGINE 
end

class Object 
	def duck_query(method)
		eval("self.#{method}") if self.respond_to? method
	end
end

module Rush
	Version = '0.6.7'
end

# The top-level Crush module has some convenience methods for accessing the
# local box.
module Crush
	Version = '1.1.0-ll'
	ConfigDir = '.crush'

	# Access the root filesystem of the local box.  Example:
	#
	#   Crush['/etc/hosts'].contents
	#
	def self.[](key)
		box[key]
	end

	# Create a dir object from the path of a provided file.  Example:
	#
	#   Crush.dir(__FILE__).files
	#
	def self.dir(filename)
		box[::File.expand_path(::File.dirname(filename)) + '/']
	end

	# Create a dir object based on the shell's current working directory at the
	# time the program was run.  Example:
	#
	#   Crush.launch_dir.files
	#
	def self.launch_dir
		box[::Dir.pwd + '/']
	end

	# Run a bash command in the root of the local machine.  Equivalent to
	# Crush::Box.new.bash.
	def self.bash(command, options={})
		box.bash(command, options)
	end

	# Pull the process list for the local machine.  Example:
   #
   #   Crush.processes.filter(:cmdline => /ruby/)
	#
	def self.processes
		box.processes
	end

	# Get the process object for this program's PID.  Example:
   #
   #   puts "I'm using #{Crush.my_process.mem} blocks of memory"
	#
	def self.my_process
		box.processes.filter(:pid => ::Process.pid).first
	end

	# Create a box object for localhost.
	def self.box
		@@box = Crush::Box.new unless @@box
		@@box
	end

	# Quote a path for use in backticks, say.
	def self.quote(path)
		path.gsub(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/n, '\\').gsub(/\n/, "'\n'").sub(/^$/, "''")
	end
end

module Crush::Connection; end

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'crush/exceptions'
require 'crush/config'
require 'crush/commands'
require 'crush/access'
require 'crush/entry'
require 'crush/file'
require 'crush/dir'
require 'crush/search_results'
require 'crush/head_tail'
require 'crush/find_by'
require 'crush/string_ext'
require 'crush/fixnum_ext'
require 'crush/array_ext'
require 'crush/process'
require 'crush/process_set'
require 'crush/local'
require 'crush/remote'
require 'crush/ssh_tunnel'
require 'crush/box'
require 'crush/embeddable_shell'

