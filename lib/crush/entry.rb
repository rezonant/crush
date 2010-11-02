# Crush::Entry is the base class for Crush::File and Crush::Dir.  One or more of
# these is instantiated whenever you use square brackets to access the
# filesystem on a box, as well as any other operation that returns an entry or
# list of entries.
class Crush::Entry
	attr_reader :box, :name, :path

	# Initialize with full path to the file or dir, and the box it resides on.
	def initialize(full_path, box=nil)
		full_path = ::File.expand_path(full_path, '/')
		@path = ::File.dirname(full_path)
		@name = ::File.basename(full_path)
		@box = box || Crush::Box.new('localhost')
	end

	# The factory checks to see if the full path has a trailing slash for
	# creating a Crush::Dir rather than the default Crush::File.
	def self.factory(full_path, box=nil)
		if full_path.tail(1) == '/' or File.directory?(full_path)
			Crush::Dir.new(full_path, box)
		else
			Crush::File.new(full_path, box)
		end
	end

	def link_to(dest)
		if dest.kind_of? String
			if dir(dest).exist?
				dest = dir(dest) 
			else
				dest = dir(File.dirname(dest)) / File.basename(dest) if dir(File.dirname(dest)).exist?
			end
		elsif dest.kind_of? Crush::Dir
			dest = dest / self.name
		end

		raise Exception.new "File already exists!" if dest.exist?
		system "ln -s '#{self.full_path}' '#{dest.full_path}'"
	end

	def <=> (other)
		name <=> other.name
	end
	
	def to_s      # :nodoc:
		if box.host == 'localhost'
			"#{full_path}"
		else
			inspect
		end
	end

	def inspect   # :nodoc:
		"#{box}:#{full_path}"
	end

	def connection
		box ? box.connection : Crush::Connection::Local.new
	end

	# The parent dir.  For example, box['/etc/hosts'].parent == box['etc/']
	def parent
		@parent ||= Crush::Dir.new(@path)
	end

	def fancy_name
		name
	end
	
	def full_path
		(@path == @name and @name == '/') ? @path : "#{@path}/#{@name}"
	end

	def quoted_path
		Crush.quote(full_path)
	end

	# The traditional Crush name for the exist? method
	def exists?
		exist?
	end
	
	# Return true if the entry currently exists on the filesystem of the box.
	# This is called "exists?" in Crush, but is not idiomatic when you look at 
	# standard naming, for instance String.include?, Object.respond_to?, etc.
	def exist?
		stat
		true
	rescue Crush::DoesNotExist
		false
	end

	# Timestamp of most recent change to the entry (permissions, contents, etc).
	def changed_at
		stat[:ctime]
	end

	# Timestamp of last modification of the contents.
	def last_modified
		stat[:mtime]
	end

	# Timestamp that entry was last accessed (read from or written to).
	def last_accessed
		stat[:atime]
	end

	# Attempts to rename, copy, or otherwise place an entry into a dir that already contains an entry by that name will fail with this exception.
	class NameAlreadyExists < Exception; end

	# Do not use rename or duplicate with a slash; use copy_to or move_to instead.
	class NameCannotContainSlash < Exception; end

	# Rename an entry to another name within the same dir.  The object's name
	# will be updated to match the change on the filesystem.
	def rename(new_name)
		connection.rename(@path, @name, new_name)
		@name = new_name
		self
	end

	# Rename an entry to another name within the same dir.  The existing object
	# will not be affected, but a new object representing the newly-created
	# entry will be returned.
	def duplicate(new_name)
		raise Crush::NameCannotContainSlash if new_name.match(/\//)
		new_full_path = "#{@path}/#{new_name}"
		connection.copy(full_path, new_full_path)
		self.class.new(new_full_path, box)
	end
	
	# Copy the entry to another dir.  Returns an object representing the new
	# copy.
	def copy_to(dir)
		raise Crush::NotADir unless dir.class == Crush::Dir

		if box == dir.box
			connection.copy(full_path, dir.full_path)
		else
			archive = connection.read_archive(full_path)
			dir.box.connection.write_archive(archive, dir.full_path)
		end

		new_full_path = "#{dir.full_path}#{name}"
		self.class.new(new_full_path, dir.box)
	end

	# Move the entry to another dir.  The object will be updated to show its new
	# location.
	def move_to(dir)
		moved = copy_to(dir)
		destroy :sure, :dir
		mimic(moved)
	end

	def mimic(from)      # :nodoc:
		@box = from.box
		@path = from.path
		@name = from.name
	end

	# Unix convention considers entries starting with a . to be hidden.
	def hidden?
		name.slice(0, 1) == '.'
	end

	# Set the access permissions for the entry.
	#
	# Permissions are set by role and permissions combinations which can be specified individually
	# or grouped together.  :user_can => :read, :user_can => :write is the same
	# as :user_can => :read_write.
	#
	# You can also insert 'and' if you find it reads better, like :user_and_group_can => :read_and_write.
	#
	# Any permission excluded is set to deny access.  The access call does not set partial
	# permissions which combine with the existing state of the entry, like "chmod o+r" would.
	#
	# Examples:
	#
	#   file.access = { :user_can => :read_write, :group_other_can => :read }
	#   dir.access = { :user => 'adam', :group => 'users', :read_write_execute => :user_group }
	#
	def access=(options)
		connection.set_access(full_path, Crush::Access.parse(options))
	end

	# These are convenience functions for singlein-place changes.
	
	def user_can_read=(b)
		a = access
		a[:user_can_read] = b
		self.access = a
	end
	def user_can_write=(b)
		a = access
		a[:user_can_write] = b
		self.access = a
	end
	def user_can_execute=(b)
		a = access
		a[:user_can_execute] = b
		self.access = a
	end
	
	def group_can_read=(b)
		a = access
		a[:group_can_read] = b
		self.access = a
	end
	def group_can_write=(b)
		a = access
		a[:group_can_write] = b
		self.access = a
	end
	def group_can_execute=(b)
		a = access
		a[:group_can_execute] = b
		self.access = a
	end
	
	def other_can_read=(b)
		a = access
		a[:other_can_read] = b
		self.access = a
	end
	def other_can_write=(b)
		a = access
		a[:other_can_write] = b
		self.access = a
	end
	def other_can_execute=(b)
		a = access
		a[:other_can_execute] = b
		self.access = a
	end
	
	# Returns a hash with up to nine values, combining user/group/other with read/write/execute.
	# The key is omitted if the value is false.
	#
	# Examples:
	#
	#   entry.access                   # -> { :user_can_read => true, :user_can_write => true, :group_can_read => true }
	#   entry.access[:other_can_read]  # -> true or nil
	#
	def access
		#Crush::Access.new.from_octal(stat[:mode]).display_hash
		Crush::Access.new.from_octal(stat[:mode])
	end

	def chmod(modifiers)
		a = access
		modifiers.each do |k,v| 
			a[k] = v
		end
		self.access = a
	end
	
	# Destroy the entry.  If it is a dir, everything inside it will also be destroyed.
	def destroy(*options)
		connection.destroy(full_path)
	end

	def delete(*options); destroy(*options); end;
	def remove(*options); destroy(*options); end;
	def unlink(*options); destroy(*options); end;

	def ==(other)       # :nodoc:
		other.respond_to?(:full_path) and 
				other.respond_to?(:box) and
				full_path == other.full_path and 
				box == other.box
	end

	def __stat
		stat
	end
private

	def stat
		connection.stat(full_path)
	end
end
