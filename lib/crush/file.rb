# Files are a subclass of Crush::Entry.  Most of the file-specific operations
# relate to manipulating the file's contents, like search and replace.
class Crush::File < Crush::Entry
	def dir?
		false
	end

	# Create a blank file.
	def create
		write('')
		self
	end
	
	def destroy(*options)
		if not exists?
			raise Crush::DoesNotExist.new full_path
		end
		
		if entries.length > 0 and not options.member? :sure
			puts "You are about to delete `#{self.name}' from: "
			puts " Path:  #{self.full_path}"
			puts " Host:  #{self.box}"
			puts
			print "Are you :sure? [y/N] "
			
			a = STDIN.readline
			a.strip!
			a.downcase!
			
			if a != 'y'
				puts "you know, #{a} != 'y'"
				puts "Operation cancelled."
				return false
			end
		end
		
		super(*options)
		true
	end
	
	# Size in bytes on disk.
	def size
		stat[:size]
	end

	def executable?
		self.access[:user_can_execute] or self.access[:group_can_execute] or self.access[:other_can_execute]	
	end
	
	# Raw contents of the file.  For non-text files, you probably want to avoid
	# printing this on the screen.
	def contents
		connection.file_contents(full_path)
	end

	alias :read :contents

	# Write to the file, overwriting whatever was already in it.
	#
	# Example: file.write "hello, world\n"
	def write(new_contents)
		connection.write_file(full_path, new_contents)
	end

	# Append new contents to the end of the file, keeping what was in it.
	def append(contents)
		connection.append_to_file(full_path, contents)
	end
	alias_method :<<, :append

	# Return an array of lines from the file, similar to stdlib's File#readlines.
	def lines
		contents.split("\n")
	end

	def open
		box.bash("xdg-open #{full_path} &")
		:sshh
	end
	
	# Search the file's for a regular expression.  Returns nil if no match, or
	# each of the matching lines in its entirety.
	#
	# Example: box['/etc/hosts'].search(/localhost/) # -> [ "127.0.0.1 localhost\n", "::1 localhost\n" ]
	def search(pattern)
		matching_lines = lines.select { |line| line.match(pattern) }
		matching_lines.size == 0 ? nil : matching_lines
	end

	def mime_type
		# TODO: does not work for remote
		`file -i #{full_path}`.strip.split(':')[1].strip
	end
	
	def mime_type!
		# TODO: does not work for remote
		print mime_type
	end
	
	def file_type
		`file #{full_path}`.strip.split(':')[1].strip
	end
	
	def file_type!
		print file_type
	end
	
	# Search-and-replace file contents.
	#
	# Example: box['/etc/hosts'].replace_contents!(/localhost/, 'local.host')
	def replace_contents!(pattern, replace_with)
		write contents.gsub(pattern, replace_with)
	end

	# Return the file's contents, or if it doesn't exist, a blank string.
	def contents_or_blank
		contents
	rescue Crush::DoesNotExist
		""
	end

	# Count the number of lines in the file.
	def line_count
		lines.size
	end

	# Return an array of lines, or an empty array if the file does not exist.
	def lines_or_empty
		lines
	rescue Crush::DoesNotExist
		[]
	end

	include Crush::Commands

	def entries
		[ self ]
	end
end
