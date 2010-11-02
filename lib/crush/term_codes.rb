class Symbol
	def to_color
		eval("Term::Foreground#{f.to_s.capitalize}")
	end
end

module Term
	class ::String 
		def term_length
			self.gsub(/\e\[[0-9;]*m/, '').length
		end
	end
	
	class String < ::String
		def length
			term_length
		end
	end
	

	Reset = "\e[0m"				# reset; clears all colors and styles (to white on black)
	BoldOn = "\e[1m"			# bold on (see below)
	DimOn = "\e[2m"				# turn low intensity mode on
	BlinkOn = "\e[4m"			# turn blink on
	
	ItalicsOn = "\e[3m"			# italics on
	UnderlineOn = "\e[4m"		# underline on
	InverseOn = "\e[7m"			# inverse on; reverses foreground & background colors
	StrikethroughOn = "\e[9m"	# strikethrough on
	BoldOff = "\e[22m"			# normal intensity
	DimOff = "\e[22m"			# normal intensity
	ItalicsOff = "\e[23m"		# italics off
	UnderlineOff = "\e[24m"		# underline off
	InverseOff = "\e[27m"		# inverse off
	StrikethroughOff = "\e[29m"	# strikethrough off
	ForegroundBlack = "\e[30m"	# set foreground color to black
	ForegroundRed = "\e[31m"	# set foreground color to red
	ForegroundGreen = "\e[32m"	# set foreground color to green
	ForegroundYellow = "\e[33m"	# set foreground color to yellow
	ForegroundBlue = "\e[34m"	# set foreground color to blue
	ForegroundMagenta = "\e[35m"# set foreground color to magenta (purple)
	ForegroundCyan = "\e[36m"	# set foreground color to cyan
	ForegroundWhite = "\e[37m"	# set foreground color to white
	ForegroundDefault = "\e[39m"# set foreground color to default (white)
	BackgroundBlack = "\e[40m"  # set background color to black
	BackgroundRed = "\e[41m"	# set background color to red
	BackgroundGreen = "\e[42m"	# set background color to green
	BackgroundYellow = "\e[43m"	# set background color to yellow
	BackgroundBlue = "\e[44m"	# set background color to blue
	BackgroundMagenta = "\e[45m"# set background color to magenta (purple)
	BackgroundCyan = "\e[46m"	# set background color to cyan
	BackgroundWhite = "\e[47m"	# set background color to white
	BackgroundDefault = "\e[49m"# set background color to default (black)
	NewTitle = "\e]2;"			# set the title bar text in xterm-compatible terminals
	NewIconName = "\e]1;"		# set the icon name in xterm-compatible terminals
	NewIconNameAndTitle = "\e]0;"# set the icon name and title in xterm-compatible terminals
	Bell = "\a"					# bell/audible character, also string terminator for xterm control sequences
	
	def Term.setTitle(newTitle)
		print NewTitle + newTitle + Bell
	end
	
	def Term.setIcon(newIconName)
		print NewIconName + newIconName + Bell
	end
	
	def Term.dim(s)
		DimOn + s + DimOff
	end
	
	def Term.bold(s)
		BoldOn + s + BoldOff
	end
	
	def Term.underline(s)
		UnderlineOn + s + UnderlineOff
	end
	
	def Term.italics(s)
		ItalicsOn + s + ItalicsOff
	end
	
	def Term.inverse(s)
		InverseOn + s + InverseOff
	end
	
	def Term.strike(s)
		StrikethroughOn + s + StrikethroughOff
	end
end
