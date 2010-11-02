# A class to hold permissions (read, write, execute) for files and dirs.
# See Crush::Entry#access= for information on the public-facing interface.
class Crush::Access
	attr_accessor :user_can_read, :user_can_write, :user_can_execute
	attr_accessor :group_can_read, :group_can_write, :group_can_execute
	attr_accessor :other_can_read, :other_can_write, :other_can_execute

	def self.roles
		%w(user group other)
	end

	def self.permissions
		%w(read write execute)
	end

	def parse(options)
		options.each do |key, value|
			next unless m = key.to_s.match(/(.*)_can$/)
			key = m[1].to_sym
			roles = extract_list('role', key, self.class.roles)
			perms = extract_list('permission', value, self.class.permissions)
			set_matrix(perms, roles)
		end
		self
	end

	def self.parse(options)
		new.parse(options)
	end

	def apply(full_path)
		FileUtils.chmod(octal_permissions, full_path)
	rescue Errno::ENOENT
		raise Crush::DoesNotExist, full_path
	end

	def hash
		to_hash
	end

	def to_hash
		hash = {}
		self.class.roles.each do |role|
			self.class.permissions.each do |perm|
				key = "#{role}_can_#{perm}".to_sym
				hash[key] = send(key) ? 1 : 0
			end
		end
		hash
	end

	def display_hash
		hash = {}
		to_hash.each do |key, value|
			hash[key] = true if value == 1
		end
		hash
	end

	def from_hash(hash)
		self.class.roles.each do |role|
			self.class.permissions.each do |perm|
				key = "#{role}_can_#{perm}"
				send("#{key}=".to_sym, hash[key.to_sym].to_i == 1 ? true : false)
			end
		end
		self
	end

	def self.from_hash(hash)
		new.from_hash(hash)
	end

	def octal_permissions
		perms = [ 0, 0, 0 ]
		perms[0] += 4 if user_can_read
		perms[0] += 2 if user_can_write
		perms[0] += 1 if user_can_execute
		
		perms[1] += 4 if group_can_read
		perms[1] += 2 if group_can_write
		perms[1] += 1 if group_can_execute

		perms[2] += 4 if other_can_read
		perms[2] += 2 if other_can_write
		perms[2] += 1 if other_can_execute

		eval("0" + perms.join)
	end

	def from_octal(mode)
		perms = octal_integer_array(mode)
		self.user_can_read = (perms[0] & 4) > 0 ? true : false
		self.user_can_write = (perms[0] & 2) > 0 ? true : false
		self.user_can_execute = (perms[0] & 1) > 0 ? true : false
	
		# if permissions are zeroed, this can happen
		perms[1] = 0 unless perms[1]
		perms[2] = 0 unless perms[2]
		
		self.group_can_read = (perms[1] & 4) > 0 ? true : false
		self.group_can_write = (perms[1] & 2) > 0 ? true : false
		self.group_can_execute = (perms[1] & 1) > 0 ? true : false

		self.other_can_read = (perms[2] & 4) > 0 ? true : false
		self.other_can_write = (perms[2] & 2) > 0 ? true : false
		self.other_can_execute = (perms[2] & 1) > 0 ? true : false

		self
	end

	def [](i)
		case i
		when :user_can_read; user_can_read
		when :user_can_write; user_can_write
		when :user_can_execute; user_can_execute
		when :group_can_read; group_can_read
		when :group_can_write; group_can_write
		when :group_can_execute; group_can_execute
		when :other_can_read; other_can_read
		when :other_can_write; other_can_write
		when :other_can_execute; other_can_execute
		end
	end
	
	def user_can
		caps = []
		caps << 'read' if user_can_read
		caps << 'write' if user_can_write
		caps << 'execute' if user_can_execute
		
		caps.join('_').to_sym
	end
	def user_can=(v)
		caps = v.to_s.split('_')
		user_can_read = (caps.member?('read') ? true : false)
		user_can_write = (caps.member?('write') ? true : false)
		user_can_execute = (caps.member?('execute') ? true : false)
	end
	
	def group_can
		caps = []
		caps << 'read' if group_can_read
		caps << 'write' if group_can_write
		caps << 'execute' if group_can_execute
		
		caps.join('_').to_sym
	end
	def group_can=(v)
		caps = v.to_s.split('_')
		group_can_read = (caps.member?('read') ? true : false)
		group_can_write = (caps.member?('write') ? true : false)
		group_can_execute = (caps.member?('execute') ? true : false)
	end
	
	
	def other_can
		caps = []
		caps << 'read' if other_can_read
		caps << 'write' if other_can_write
		caps << 'execute' if other_can_execute
		
		caps.join('_').to_sym
	end
	
	def to_s
		(user_can_read ? 'r' : '-') +
		(user_can_write ? 'w' : '-') +
		(user_can_execute ? 'x' : '-') +
		(group_can_read ? 'r' : '-') +
		(group_can_write ? 'w' : '-') +
		(group_can_execute ? 'x' : '-') +
		(other_can_read ? 'r' : '-') +
		(other_can_write ? 'w' : '-') +
		(other_can_execute ? 'x' : '-')
	end
	
	def other_can=(v)
		caps = v.to_s.split('_')
		other_can_read = (caps.member?('read') ? true : false)
		other_can_write = (caps.member?('write') ? true : false)
		other_can_execute = (caps.member?('execute') ? true : false)
	end
	
	def octal_integer_array(mode)
		mode = mode.to_i if mode.kind_of? String
		
		mode %= 01000                      # filter out everything but the bottom three digits
		mode = sprintf("%o", mode)         # convert to string
		mode.split("").map { |p| p.to_i }  # and finally, array of integers
	end

	def set_matrix(perms, roles)
		perms.each do |perm|
			roles.each do |role|
				meth = "#{role}_can_#{perm}=".to_sym
				send(meth, true)
			end
		end
	end

	def extract_list(type, value, choices)
		list = parts_from(value)
		list.each do |value|
			raise(Crush::BadAccessSpecifier, "Unrecognized #{type}: #{value}") unless choices.include? value
		end
	end

	def parts_from(value)
		value.to_s.split('_').reject { |r| r == 'and' }
	end
end
