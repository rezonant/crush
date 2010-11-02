require ::File.dirname(__FILE__) + '/../filter_list.rb'
module DbusCommands
	module DBus
		class ObjectList < FilterList
			def [](i)
				suffix = '/' + i
				if i.kind_of? String or i.kind_of? Symbol
					i = i.to_s
					entries.each { |x| return x if x.name == i or x.name.end_with? suffix }
					nil
				else 
					super i
				end
			end
			def ls(loc)
				dirs, items = [], []
				prefix = loc + '/'
				entries.select { |x| x.name.start_with? prefix }.each do |x|
					ent = x.name[prefix.length,x.name.length].split('/')[0]
					dirs << ent if not dirs.member? ent and x.name.length > prefix.length + ent.length
					items << ent unless items.member? ent
				end
				items.colorize(proc {|x| dirs.member?(x)} => :blue).columns
			end	
			def empty_set_label; "No objects"; end;
		end

		class DataObject < FilterList
			def initialize(service, name, *opts)
				super nil
				@service = service
				@name = name
				@options = opts
			end

			attr_reader :service, :name, :options
			def system?; options.member? :system; end

			def to_s
				self.name
			end

			def method_missing(name, *args)
				method = self[name]
				puts "hrm"
				if method
					method.call(*args)
				else
					super
				end
			end

			def inspect
				self.name
			end

			def [](i)
				if i.kind_of? String or i.kind_of? Symbol
					i = i.to_s
					entries.each { |x| return x if x.name == i }
					nil
				else
					super i
				end
			end

			def empty_set_label; "No methods"; end;
			def entries
				e = super; return e if e
				opts = []
				opts << "--system" if system?
#				puts "gonna run: qdbus #{opts.join(' ')} #{service.name} #{self.name}"
				self.entries = `qdbus #{opts.join(' ')} #{service.name} #{self.name}`.split("\n").collect {|x| Method.new service, self, x.strip }
			end
		end

		class Parameter
			def initialize (type, name)
				@type = type
				@name = name
			end

			attr_reader :type, :name

			def to_s
				if @name and @name != ''
					"#{self.type} #{self.name}"
				else
					self.type
				end
			end
		end

		class Method
			def initialize(service, object, prototype)
				@service = service
				@object = object
				@prototype = prototype
				prototype = prototype.sub(/property /, 'property-') 
				@method_type, @return_type, @full_name = prototype.split(' ')[0,3]
				puts prototype unless @full_name
				@full_name = @full_name.split('(')[0]
				@name = @full_name[@full_name.rindex('.') + 1, @full_name.length]
				@interface = @full_name[0, @full_name.rindex('.')]	

				if prototype.include? '('
					parms = prototype.split('(')[1]
					parms = parms[0, parms.length - 1]
					@parameters = parms.split(',').collect do |x| 
						x = x.strip
						if x.include? ' '
							Parameter.new *x.split(' ')[0,2]
						else
							Parameter.new x, ''
						end
					end
				else
					@parameters = []
				end
			end

			def call(*args)
				`qdbus #{service.name} #{object.name} #{full_name} #{args.collect{|x| "\"#{x}\""}.join(' ')}`
			end

			def to_s
				"#{method_type != 'method' ? '+' : ' '} #{name}(#{self.parameters.join(', ')})"
			end

			attr_reader :service, :object, :prototype, :method_type, :return_type, :full_name, :name, :interface, :parameters
		end

		class Service < ObjectList
			def initialize (name, *opts)
				super nil
				@name = name
				@options = opts
			end

			attr_reader :name, :options

			def empty_set_label; "No objects"; end;
			def system?; options.member? :system; end;

			def method_missing(m, *args)
				entries  # make sure our entries have actually been evaluated
				if @forwarding
					method = self[m]
					(method.call(*args) if method) or super
				else
					super
				end
			end

			def entries
				e = super; return e if e
				opts = []
				opts << "--system" if system?
				e = `qdbus #{opts.join(' ')} #{name}`.split("\n").collect { |x| DataObject.new self, x.strip, *@options }
				if e.length == 1
					@forwarding = e[0]
					e = e[0].entries 
				end

				self.entries = e
			end

			def [](i)
				if i.kind_of? String or i.kind_of? Symbol
					suffix = '/' + i
					i = i.to_s
					entries.each { |x| return x if x.name == i or x.name.end_with? suffix }
					nil
				else 
					super i
				end
			end	

			def to_s
				self.name
			end
		end

		class ServiceList < FilterList
			def initialize(entries = nil, *opts)
				@options = opts
				if entries
					super entries
				else
					args = []
					args << '--system' if opts.member? :system
					v = `qdbus #{args.join(' ')}`.split("\n")
					v = v.select { |x| not x.start_with? ':' } unless opts.member? :clients
					super v.collect { |x| Service.new x.strip, *@options }
				end
			end

			def empty_set_label; "No services"; end;
			def [](i)
				suffix = '.' + i
				if i.kind_of? String or i.kind_of? Symbol
					i = i.to_s
					entries.each { |x| return x if x.name == i or x.name.end_with? suffix }
					nil
				else 
					super i
				end
			end

			attr_reader :options

			def new_slice
				ServiceList.new entries, *@options
			end
		end
	end

	def dbus(*opts)
		DBus::ServiceList.new nil, *opts
	end
end
