class Array
	# Invoke vi on one or more files - only works locally.
	def vi(*args)
		names = entries.map { |f| f.quoted_path }.join(' ')
		system "vim #{names} #{args.join(' ')}"
	end
	
	# Invoke vi on one or more files - only works locally.
	def vim(*args)
		vi *args
	end
end

module Crush
	class Dir
		def vi(*args)
			names = entries.map { |f| f.quoted_path }.join(' ')
			system "vim #{args.join(' ')} -- #{names}"
		end
		
		# Invoke vi on one or more files - only works locally.
		def vim(*args)
			vi *args
		end
	end
	
	class File
		def vi(*args)
			names = entries.map { |f| f.quoted_path }.join(' ')
			system "vim #{args.join(' ')} -- #{names}"
		end
		
		# Invoke vi on one or more files - only works locally.
		def vim(*args)
			vi *args
		end
	end
end

module VimCommands
	def vim(*args)
		files = []
		options = []
		still_parsing = true

		args.each do |v|
			if still_parsing and v.start_with? '-'
				if v == '--'
					still_parsing = false
				else
					options << v
				end
			elsif v == '-+'
				still_parsing = true
			else
				($CRUSH.dir(v) if v.kind_of?(String)) or v
			end
		end

		files.vim options
		
		system "vim '#{args.join('\' \'')}'"
	end
end
