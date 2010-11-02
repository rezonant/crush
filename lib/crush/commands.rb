# The commands module contains operations against Crush::File entries, and is
# mixed in to Crush::Entry and Array.  This means you can run these commands against a single
# file, a dir full of files, or an arbitrary list of files.
#
# Examples:
#
#   box['/etc/hosts'].search /localhost/       # single file
#   box['/etc/'].search /localhost/            # entire directory
#   box['/etc/**/*.conf'].search /localhost/   # arbitrary list

require "#{::File.dirname(__FILE__)}/object_ext.rb"

module Crush::Commands
	# The entries command must return an array of Crush::Entry items.  This
	# varies by class that it is mixed in to.
	def entries
		raise "must define me in class mixed in to for command use"
	end

	def columns
		if block_given?
			Columnator.go(self) { |i| yield i }
		else
			Columnator.go(self)
		end
	end
	
	# Search file contents for a regular expression.  A Crush::SearchResults
	# object is returned.
	def search(pattern)
		results = Crush::SearchResults.new(pattern)
		entries.each do |entry|
			if !entry.dir? and matches = entry.search(pattern)
				results.add(entry, matches)
			end
		end
		results
	end
	
	def colorize(rules)
		entries.collect do |e| 
			rules.select { |r| 
				r.probe_interface(
					Proc	 => lambda { r.call(e) },
					:member? => lambda { r.member?(e) }, 
					Regexp	 => lambda { r =~ e.to_s },
					nil      => lambda { e.to_s }
				)
			}.each do |r,f| 
				if f.kind_of? Symbol
					e = eval("Term::Foreground#{f.to_s.capitalize}") + e.to_s + Term::ForegroundDefault
				else
					e = f.sub /%/, e.to_s
				end
			end
			e
		end
	end
	
	# Search and replace file contents.
	def replace_contents!(pattern, with_text)
		entries.each do |entry|
			entry.replace_contents!(pattern, with_text) unless entry.dir?
		end
	end

	# Count the number of lines in the contained files.
	def line_count
		entries.inject(0) do |count, entry|
			count += entry.lines.size if !entry.dir?
			count
		end
	end

	# Invoke TextMate on one or more files - only works locally.
	def mate(*args)
		names = entries.map { |f| f.quoted_path }.join(' ')
		system "mate #{names} #{args.join(' ')}"
	end
end
