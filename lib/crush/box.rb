# A rush box is a single unix machine - a server, workstation, or VPS instance.
#
# Specify a box by hostname (default = 'localhost').  If the box is remote, the
# first action performed will attempt to open an ssh tunnel.  Use square
# brackets to access the filesystem, or processes to access the process list.
#
# Example:
#
#   local = Crush::Box.new
#   local['/etc/hosts'].contents
#   local.processes
#

require 'rubygems'
require 'units'
require 'units/standard'

class Crush::Box
	attr_reader :host

	# Instantiate a box.  No action is taken to make a connection until you try
	# to perform an action.  If the box is remote, an ssh tunnel will be opened.
	# Specify a username with the host if the remote ssh user is different from
	# the local one (e.g. Crush::Box.new('user@host')).
	def initialize(host='localhost')
		@host = host
	end

	def to_s        # :nodoc:
		host
	end

	def inspect     # :nodoc:
		host
	end

	def user
		ENV['USERNAME']
	end
	
	# Access / on the box.
	def filesystem
		Crush::Entry.factory('/', self)
	end

	# Look up an entry on the filesystem, e.g. box['/path/to/some/file'].
	# Returns a subclass of Crush::Entry - either Crush::Dir if you specifiy
	# trailing slash, or Crush::File otherwise.
	def [](key)
		filesystem[key]
	end

	# Get the list of processes running on the box, not unlike "ps aux" in bash.
	# Returns a Crush::ProcessSet.
	def processes
		Crush::ProcessSet.new(
			connection.processes.map do |ps|
				Crush::Process.new(ps, self)
			end
		)
	end

	# Execute a command in the standard unix shell.  Returns the contents of
	# stdout if successful, or raises Crush::BashFailed with the output of stderr
	# if the shell returned a non-zero value.  Options:
	#
	# :user => unix username to become via sudo
	# :env => hash of environment variables
	# :background => run in the background (returns Crush::Process instead of stdout)
	#
	# Examples:
	#
	#   box.bash '/etc/init.d/mysql restart', :user => 'root'
	#   box.bash 'rake db:migrate', :user => 'www', :env => { :RAILS_ENV => 'production' }
	#   box.bash 'mongrel_rails start', :background => true
	#   box.bash 'rake db:migrate', :user => 'www', :env => { :RAILS_ENV => 'production' }, :reset_environment => true
	#
	def bash(command, options={})
		cmd_with_env = command_with_environment(command, options[:env])
		options[:reset_environment] ||= false

		if options[:background]
			pid = connection.bash(cmd_with_env, options[:user], true, options[:reset_environment])
			processes.find_by_pid(pid)
		else
			connection.bash(cmd_with_env, options[:user], false, options[:reset_environment])
		end
	end

	def mem_info(*options)
		proc = filesystem['proc/']
		
		mode = ($CRUSH.interactive ? :display : :details)
		
		mode = :details if options.member? :details
		mode = :display if options.member? :display
		
		if proc.exist?
			lines = (proc/:meminfo).read.split "\n"
			hash = Hash.new
			lines.each do |line|
				parts = line.gsub!(/\  +/, ' ')
				parts = parts.split(':')
				key = parts[0]
				
				key = 'HugePageSize' if key == 'Hugepagesize'			# Consistency fail...
				key = 'S_Reclaimable' if key == 'SReclaimable'			# These aren't acronyms
				key = 'S_Unreclaim' if key == 'SUnreclaim'
				
				key.gsub!(/[A-Z]+/) { |m| m.capitalize }				# deal with acronyms
				key.gsub!(/_/, '')
				key.gsub!(/[0-9][A-Z]/) { |m| m.downcase }				# 4M must be 4m not 4_m
				key.gsub!(/\(.*\)/) { |m| m[1,m.length-2].capitalize }	# deal with parantheses
				key.gsub!(/([A-Z])/) { |m| "_#{m.downcase}" } 			# replace capitals with _ and lowercase
				
				key = key[1, key.length] if key.start_with? '_'
				
				value, unit = parts[1, parts.length].join(':').split(' ')
				value = value.to_i
				
				if [ 'kB', 'kiB' ].member? unit
					units, unit_i = [ 'KiB', 'MiB', 'GiB', 'TiB' ], 0
					
					value /= 1024.0 and unit_i += 1 while value > 1024.0 and unit_i < units.length
					value = format("%0.2f", value).to_f
					unit = units[unit_i]
				end
				
				hash [key.to_sym] = "#{value} #{unit}"
			end
			
			case mode
			when :details
				hash
			when :display
				puts "RAM:  #{hash[:mem_free]} / #{hash[:mem_total]} free"
				puts "Swap: #{hash[:swap_free]} / #{hash[:swap_total]} free"
				:sshh	
			end
			
		else
			raise Exception.new 'This feature is not implemented for the operating system in use.'
		end
	end
	
	def cpu_info
		
	end
	
	def command_with_environment(command, env)   # :nodoc:
		return command unless env

		vars = env.map do |key, value|
			escaped = value.to_s.gsub('"', '\\"').gsub('`', '\\\`')
			"export #{key}=\"#{escaped}\""
		end
		vars.push(command).join("\n")
	end

	# Returns true if the box is responding to commands.
	def alive?
		connection.alive?
	end

	# This is called automatically the first time an action is invoked, but you
	# may wish to call it manually ahead of time in order to have the tunnel
	# already set up and running.  You can also use this to pass a timeout option,
	# either :timeout => (seconds) or :timeout => :infinite.
	def establish_connection(options={})
		connection.ensure_tunnel(options)
	end

	def connection         # :nodoc:
		@connection ||= make_connection
	end

	def make_connection    # :nodoc:
		host == 'localhost' ? Crush::Connection::Local.new : Crush::Connection::Remote.new(host)
	end

	def ==(other)          # :nodoc:
		host == other.host
	end
end
