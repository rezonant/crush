class Array
	def ls(*options)
		common_dir = true
		last_dir = nil

		self.entries.each do |x|
			unless x.kind_of? Crush::Entry
				common_dir = false
				break
			end

			if last_dir
				common_dir = (last_dir == x.parent.full_path)
				last_dir = x.parent.full_path
			else
				last_dir = x.parent.full_path
			end
		end

		last_dir = nil

		if options.member? :one
			out = []

			self.entries.each do |x|
				if x.kind_of? Crush::Entry
					colorized = (Dir.color_dir(x) if x.duck_query :dir?) or Dir.color_file(x)
				else
					colorized = x
				end
				out << "     " + colorized
			end

			out << "    -" + Term::dim("no entries") + "-" if out.length == 0
			
			puts out.join("\n")
		else
			entries.map do |x|
				suffix = (x.duck_query(:dir?) ? '/' : (x.duck_query(:executable?) ? '*' : ''))
				if common_dir
					::File.basename(x.full_path) + suffix
				else
					x.full_path + suffix
				end
			end .colorize(
				lambda {|x| x.to_s.end_with?('/') }		=> ($CRUSH.options[:ls_dir_color] or :blue), 
				lambda {|x| x.to_s.end_with?('*') }		=> ($CRUSH.options[:ls_exec_color] or :green)
			).columns
		end
		:sshh
	end	
end

module Math
	def Math.PI
		Math::PI
	end
end

def import(*mods)
	mods.each do |mod|
		raise Exception.new("Crush must be purely bound") unless $CRUSH.is_pure?
		if mod.kind_of? Module
			$CRUSH.bind_include mod
		else
			begin
				mod_orig = mod
				mod_file = mod.to_s
				mod_name = mod.to_s.capitalize + "Commands"
				mod = eval mod_name
				found = true
			rescue
				mod_rb = mod_file + '.rb'
				found = $CRUSH.path.select { |path| FileTest.exists?("#{path}/#{mod_rb}") }.each do |path|
					begin
						require "#{path}/#{mod_rb}"
						break true
					rescue ::Exception => e; end;
				end
				
				found = false if found == []
				
				if found == true
					mod = eval mod.to_s.capitalize + "Commands"
				end
			end
			
			if found
				$CRUSH.bind_include mod
			else
				puts "could not import shell extension `#{mod_orig}'"
			end	
			
			found
		end
	end
end

module RubyCommands
	def p
		$CRUSH.last!
	end

	def inspect(item)
		if item.kind_of? Class
			ri = `ri -f simple #{item.name}`
			puts Term::underline("The `#{item.name}` class")
			puts
			puts "Instance methods:"
		else
			
		end
		:sshh
	end

	def irb
		system 'irb'
	end

	def backtrace(e = $e)
		if e.nil? 
			"No exception has occurred."
		else
			$CRUSH.backtrace e
		end
	end

	def ri(topic)
		$CRUSH.ri topic
	end
end 

module CrushCommands
	def dir(n)
		Crush::Dir.new(n)
	end

	def help(topic = 'intro')
		$CRUSH.help topic
	end

	def run(*args)
		system args.join(" ")
	end
end

module UnixCommands
	def mount(*args)
		Crush::Box.new.bash("mount #{args.join(" ")}")
	end

	def whoami
		`whoami`.strip
	end

	def ps
		Crush::Box.new.processes
	end

	def who
		utmp.unpack 'S_I_A32A4A32A256SSI_I_I_lA20'
	end
	
	def man(topic)
		system 'man ' + topic
	end

	def echo(v)
		puts v
		:sshh
	end

	def printf(v)
		print v
		:sshh
	end
	def ssh(host)
		$CRUSH.ssh host
	end
end

module WdCommands
	def chdir(dest = nil)
		$CRUSH.cd dest
	end

	alias :cd :chdir

	def wd()
		$CRUSH.wd
	end

	def pwd()
		echo $CRUSH.wd.inspect
	end
end

module TermCommands
	def reset()
		system 'reset'
		:sshh
	end
		
	def clear()
		$CRUSH.clear
	end
	
	alias :cls :clear
end

module CoreCommands
	def time()
		t = Time.now
		yield
		Time.now - t
	end
end

module PrettyCommands
	def columns(items)
		if block_given? 
			Columnator.go(items) { |x| yield x }
		else
			Columnator.go(items)
		end
	end
end

module FileCommands
	def ls(dest = ".")
		$CRUSH.ls(dest)
	end
		
	def mv(from, to, verbose = false)
		$CRUSH.mv from, to, verbose
	end
end
