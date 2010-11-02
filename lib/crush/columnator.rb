class Columnator
	def initialize
		@format = proc { |x| [x.to_s, x.to_s.term_length] }
	end
	
	attr_accessor :format
	
private
	def max_idx
		[1, $CRUSH.columns / Crush::MinColumnWidth].max
	end
	
	def calc_columns(items, by_columns = true)
		cols = 0			# Number of files across.
		
		# Normally the maximum number of columns is determined by the
		# screen width.  But if few files are available this might limit it
		# as well. 
		
		max_cols = [max_idx, items.length].min

		column_info = []
		max_cols.times do |i|
			column_info << [ true, (i + 1) * Crush::MinColumnWidth, [ Crush::MinColumnWidth ] * (i + 1), i ]
		end
		
		# Compute the maximum number of possible columns. 
		filesno = 0
		
		entry_len = items.length
		line_len = $CRUSH.columns
		
		items.each do |f|
			name_length = @format.call(f)[1] + 1
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
	def color_dir(d)
		Term::ForegroundCyan + d.fancy_name + Term::ForegroundDefault
	end
	
	def color_file(f)
		if f.executable
			Term::ForegroundGreen + f.fancy_name + Term::ForegroundDefault
		else
			f.fancy_name
		end
	end
	
	def Columnator.go(items, &block)
		c = Columnator.new
		c.format = proc { |x| yield x } if block_given?
		c.show(items)
	end
	
	# Text output of dir listing, equivalent to the regular unix shell's ls command.
	def show(items)
		width = $CRUSH.columns
		line_len = 0
		
		items.each do |x|
			str, len = @format.call(x)
			line_len += (len or str.term_length) + 2
		end
		
		line_len -= 2
		line = items.join('  ')
		
		if (line_len >= width)
			line_fmt = calc_columns(items, true)
			cols = line_fmt[3]
			col_arr = line_fmt[2]
			entry_len = items.length
			rows = entry_len / cols + (entry_len % cols != 0 ? 1 : 0)
			rows.times do |row|
				filesno = row
				pos = 0
				chunks = []
				cols.times do |col|
					break if filesno >= entry_len
					
					fancy_name, fancy_len = @format.call(items[filesno])
					fancy_len = fancy_name.term_length unless fancy_len
					
					max_name_length = col_arr[col]
					
					chunks << fancy_name + " " * [0, (max_name_length - fancy_len)].max
					
					filesno += rows
					pos += max_name_length
				end
				
				puts chunks.join
			end
		else
			puts line
		end
	end
	:sshh
end
