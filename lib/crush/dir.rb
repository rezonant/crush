# A dir is a subclass of Crush::Entry that contains other entries.  Also known
# as a directory or a folder.
#
# Dirs can be operated on with Crush::Commands the same as an array of files.
# They also offer a square bracket accessor which can use globbing to get a
# list of files.
#
# Example:
#
#   dir = box['/home/adam/']
#   dir['**/*.rb'].line_count
#
# In the interactive shell, dir.ls is a useful command.

module Crush
	# Minimum width for columns
	MinColumnWidth = 3
end

class Crush::Dir < Crush::Entry
	def dir?
		true
	end

	def full_path
		v = super
		return v if v == '/'
		"#{v}/"
	end

	def method_missing(name, *args)
		$CRUSH.options[:dir_method_missing] ? (self / name) : super
	end

	def destroy(*options)
		if options.member? :dir
			if entries.length > 0 and not options.member? :sure
				puts "This directory contains #{entries.length} entries! All subdirectories and files"
				puts "will be lost! Are you :sure ?"
				print "[y/N] "
				a = STDIN.readline.strip
				
				if a.downcase != 'y'
					puts "Operation cancelled."
					return false
				end
			end
			
			super(*options)
			true
		else
			puts "Target is a directory! Use the :dir argument if you wish to proceed."
			false	
		end
	end
	
	# Entries contained within this dir - not recursive.
	def contents
		find_by_glob('*')
	end

	# Files contained in this dir only.
	def files
		contents.select { |entry| !entry.dir? }
	end


	# Other dirs contained in this dir only.
	def dirs
		contents.select { |entry| entry.dir? }
	end

	# Access subentries with square brackets, e.g. dir['subdir/file'] 
	def [](key)
		key = key.to_s
		if key == '**'
			files_flattened
		elsif key.match(/\*/)
			find_by_glob(key)
		else
			find_by_name(key)
		end
	end
	
	# Slashes work as well, e.g. dir/'subdir/file'
	alias_method :/, :[] 		# def /
	alias_method :+, :[] 		# def +
	
	def find_by_name(name)    # :nodoc:
		Crush::Entry.factory("#{full_path}/#{name}", box)
	end

	def find_by_glob(glob)    # :nodoc:
		connection.index(full_path, glob).map do |fname|
			Crush::Entry.factory("#{full_path}/#{fname}", box)
		end
	end

	# A list of all the recursively contained entries in flat form.
	def entries_tree
		find_by_glob('**/*')
	end

	# Recursively contained files.
	def files_flattened
		entries_tree.select { |e| !e.dir? }
	end

	# Recursively contained dirs.
	def dirs_flattened
		entries_tree.select { |e| e.dir? }
	end

	# Given a list of flat filenames, product a list of entries under this dir.
	# Mostly for internal use.
	def make_entries(filenames)
		filenames.map do |fname|
			Crush::Entry.factory("#{full_path}/#{fname}")
		end
	end

	# Create a blank file within this dir.
	def create_file(name)
		file = self[name].create
		file.write('')
		file
	end

	# Create an empty subdir within this dir.
	def create_dir(name)
		name += '/' unless name.tail(1) == '/'
		self[name].create
	end

	alias :mkdir :create_dir
	
	# Create an instantiated but not yet filesystem-created dir.
	def create
		connection.create_dir(full_path)
		self
	end

	# Get the total disk usage of the dir and all its contents.
	def size
		connection.size(full_path)
	end

	# Contained dirs that are not hidden.
	def nonhidden_dirs
		dirs.select do |dir|
			!dir.hidden?
		end
	end

	# Contained files that are not hidden.
	def nonhidden_files
		files.select do |file|
			!file.hidden?
		end
	end

	# Run a bash command starting in this directory.  Options are the same as Crush::Box#bash.
	def bash(command, options={})
		box.bash "cd #{quoted_path} && #{command}", options
	end

	# Destroy all of the contents of the directory, leaving it fresh and clean.
	def purge
		connection.purge full_path
	end

	def fancy_name
		name + "/"
	end
private
	def line_length
		$CRUSH.columns
	end
	
	def max_idx
		[1, line_length / Crush::MinColumnWidth].max
	end
	
	def calc_columns(by_columns)
		cols = 0			# Number of files across.
		
		# Normally the maximum number of columns is determined by the
		# screen width.  But if few files are available this might limit it
		# as well. 
		
		max_cols = [max_idx, entries.length].min

		column_info = []
		max_cols.times do |i|
			column_info << [ true, (i + 1) * Crush::MinColumnWidth, [ Crush::MinColumnWidth ] * (i + 1), i ]
		end
		
		# Compute the maximum number of possible columns. 
		filesno = 0
		
		entry_len = entries.length
		line_len = line_length
		
		entries.each do |f|
			name_length = f.fancy_name.length + 1
			max_cols.times do |i|
				info = column_info[i]

				# 0 => :valid_len
				# 1 => :line_len
				# 2 => :col_arr
				# 3 => :columns
						
				if info[0]
					if by_columns
						idx = filesno / ((entry_len + i) / (i + 1))
					else
						idx = filesno % (i + 1)
					end
					
					real_length = name_length + (idx == i ? 0 : 2);
					
					col_arr = info[2]
					col_arr_idx = col_arr[idx]
					
					if col_arr_idx < real_length
						info[1] = info_line_len = info[1] + (real_length - col_arr_idx)
						
						col_arr[idx] = real_length
						info[0] = (info_line_len < line_len)
					end
				end
			end
			
			filesno += 1
		end
		
		# Find maximum allowed columns.
		cols = max_cols
		max_cols.downto(2) do |j|
			cols = j
			break if column_info[cols - 1][0]
		end

		column_info[cols - 1]
	end
public
	def Dir.color_dir(d)
		dir_color = ($CRUSH.options[:ls_dir_color] or :blue)
		dir_color + d.fancy_name + Term::ForegroundDefault
	end
	
	def Dir.color_file(f)
		exec_color = ($CRUSH.options[:ls_dir_color] or :green)
		if f.executable?
			exec_color + f.fancy_name + Term::ForegroundDefault
		else
			f.fancy_name
		end
	end

	def nonhidden_entries
		nonhidden_dirs + nonhidden_files
	end
	
	# Text output of dir listing, equivalent to the regular unix shell's ls command.
	def ls(*options)
		if ($CRUSH.options[:ls_show_heading] or options.member?(:heading)) and not options.member?(:no_heading)
			puts Term::underline(self.inspect)
		end
	
		if options.member? :all
			dir_list = dirs
			file_list = files
		else
			dir_list = nonhidden_dirs
			file_list = nonhidden_files
		end	
		
		(dir_list + file_list).ls *options
		return :sshh
		if options.member? :one
			out = []
			
			nonhidden_dirs.each do |dir|
				out << "    " + Term::ForegroundCyan + dir.name + "/" + Term::ForegroundDefault
			end
			nonhidden_files.each do |file|
				out << "    " + color_file(file)
			end
			
				out << "    -" + Term::dim("no entries") + "-" if out.length == 1
			
			puts out.join("\n")
		else
			entries.map do |x|
				::File.basename(x.full_path) + (x.dir?() ? '/' : '') 
			end .colorize(
				lambda {|x| x.to_s.end_with? '/' }							=> :blue, 
				lambda {|x| (self/x).executable? unless (self/x).dir? }		=> :green
			).columns
		end
		:sshh
	end

	def cd
		$CRUSH.cd self
	end
	
	# Run rake within this dir.
	def rake(*args)
		bash "rake #{args.join(' ')}"
	end

	# Run git within this dir.
	def git(*args)
		bash "git #{args.join(' ')}"
	end

	include Crush::Commands

	def entries
		contents
	end
end
