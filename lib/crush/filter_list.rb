class FilterList
	def initialize(items)
		self.entries = items
	end

	def method_missing(name, *args)
		self[name] or super
	end

	def [](i)
		entries[i]
	end

	def each(&b)
		entries.each &b
	end

	def select(&b)
		new_slice entries.select &b
	end

	def fp(*a) filter_pick(*a) end
	def f(*a) filter(*a) end
	
	def length
		entries.length
	end

	def filter_pick(pred)
		r = f(pred)
		r[0]
	end

	def new_slice(entries)
		FilterList.new entries
	end

	def filter(pred)
		if pred.respond_to? :call
			new_slice entries.select { |x| pred.call x }
		elsif pred.respond_to? :=~
			new_slice entries.select { |x| pred =~ x }
		else
			new_slice entries.select { |x| pred == x }
		end
	end

	attr_accessor :entries
=begin
	def entries
		@entries
	end

	def entries=(v)
		@entries = v
	end
=end
end
