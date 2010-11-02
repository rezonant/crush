require File.dirname(__FILE__) + "/term_codes.rb"

class Crush::Help
	def initialize()
		
	end
	
private

	def term_title(title)
		Term::UnderlineOn + title + Term::UnderlineOff
	end
	
	def term_url(text)
		Term::UnderlineOn + Term::ForegroundBlue + text + Term::UnderlineOff + Term::ForegroundDefault
	end
	
public

	def splash
		puts
		puts "welcome to " + Term::BoldOn +
				Term::ForegroundMagenta  + "c" + Term::ForegroundBlue + "ru" + Term::ForegroundCyan + "sh" + Term::ForegroundDefault +
				Term::BoldOff + " v." + version
		puts 
		puts "   (c) 2008-2010 Adam Wiggins, Liam Lahti"
		puts "   " + term_url("http://stridetechnologies.net/crush")
		puts "   " + term_url("http://rush.heroku.com/")
		puts
		puts " - use #{Term::underline("help")} to get help"
		puts " - use #{Term::underline("help :license")} for license information"
		:sshh
	end
	
	def version
		"#{Crush::Version} (from rush #{Crush::Version})"
	end
	
	def topic(topic)
		if topic.kind_of? Symbol
			topic = topic.to_s
		end
		
		c = Term::ForegroundBlue
		v = Term::ForegroundMagenta
		s = Term::DimOn + Term::ForegroundYellow
		d = Term::DimOff + Term::ForegroundDefault
		crush = "#{Term::DimOn}crush> #{Term::DimOff}"
		
		topic = 'cd' if topic == 'chdir' or topic == 'Crush::Shell.cd' or topic == 'shell.cd' or topic == 'Shell.cd'
		topic = 'wd' if topic == 'Crush::Shell.wd' or topic == 'shell.wd' or topic == 'Shell.wd'
		topic = 'ls' if topic == 'Crush::Shell.ls' or topic == 'shell.ls' or topic == 'Shell.ls' or topic == 'Dir.ls' or
				topic == 'Crush::Dir.ls'
		topic = 'intro' if topic == 'help'
		puts
		case topic
		when 'intro'
			puts term_title "Welcome to the Crush help system!"
			puts
			puts "The Crush documentation provided by the `help' command is divided into "
			puts "pages based on topic of interest. You access pages via their symbol. These"
			puts "two commands will both open the Overview page:"
			puts "  help :overview"
			puts "  help 'overview'"
			puts
			puts Term::underline("Index")
			puts "  " + term_url(":overview") + " -- an overview of the crush command shell"
			puts "  " + term_url(":license") +  " -- license and copyright information"
			puts
			puts "  " + term_url(":bash") +  " -- run BASH commands"
			puts "  " + term_url(":cd") +  " -- change working directory"
			puts "  " + term_url(":commandline") +  " -- crush command line argument behavior"
			puts "  " + term_url(":Dir") +  " -- represents a directory"
			puts "  " + term_url(":File") +  " -- represents a file"
			puts "  " + term_url(":loops") + " -- do things multiple times"
			puts "  " + term_url(":ls") +  " -- list given/current directory"
			puts "  " + term_url(":prompt") +  " -- customize the crush prompt"
			puts "  " + term_url(":reporter") +  " -- the crush value reporter"
			puts "  " + term_url(":reset") +  " -- reset the terminal"
			puts "  " + term_url(":ri") +  " -- ruby information from within crush"
			puts "  " + term_url(":syntax") +  " -- brief overview of ruby and crush syntax"
			puts "  " + term_url(":wd") +  " -- retrieve working directory"
		when 'overview'																	#	 X
			puts term_title "Overview"
			puts
			puts "crush 1.0 by Liam Lahti"
			puts "  " + term_url("http://stridetechnologies.net/crush")
			puts
			puts "based on " + Term::bold(Term::ForegroundWhite + "ru" + Term::ForegroundCyan + "sh" + Term::ForegroundDefault) +
					" by Adam Wiggins"
			puts "  " + term_url("http://rush.heroku.com/")
			puts
			puts Term::underline("predefined variables")
			puts "  #{v}shell#{d} -- access to the main shell object. aliases: rush, $CRUSH"
			puts "  #{v}home#{d}  -- a Crush::Dir for your home directory"
			puts "  #{v}root#{d}  -- a Crush::Dir for the root directory of the local host"
			puts "  #{v}box#{d}   -- a Crush::Box for the local system, same as top-level scope from"
			puts "           command-line"
			puts
			puts Term::underline("working directory")
			puts "  #{crush}#{c}wd#{d}          -- retrieve working directory"
			puts "  #{crush}#{c}cd#{d} #{s}'path'#{d}   -- change working directory. without argument, returns"
			puts "  #{crush}#{c}#{d}               to home directory"
			puts "  #{crush}#{c}ls#{d} #{s}'path'#{d}   -- list files of the given path. if no argument, lists files of wd"
			puts
			puts Term::underline("convenience")
			puts "  #{crush}#{c}mv#{d}  #{s}'from', 'to'#{d} -- move a file  #=> Crush::File"
			puts "  #{crush}#{c}cp#{d}  #{s}'from', 'to'#{d} -- copy a file  #=> Crush::File"
			puts "  #{crush}#{c}rm#{d}  #{s}'file'#{d}      -- remove a file or empty directory"
			puts "  #{crush}#{c}rmf#{d} #{s}'file'#{d}      -- force remove a file or directory"
			puts "  #{crush}#{c}ssh#{d} #{s}'user@host'#{d} -- start an SSH session"
			puts
			puts Term::underline("bash commands")
			puts "  #{crush}$ #{s}echo hello#{d}"
 			puts "  #{crush}#{c}bash#{d} #{s}'echo hello'#{d}"
 			puts "  #{crush}foo = #{s}`echo hello`#{d}"
			puts "  For more information see " + term_url(":bash")
		when 'bind'
			puts term_title "The `shell.bind' method"
			puts
			puts "  When crush runs interactively, it uses a persistent execution context called a binding so"
			puts "  that variables and definitions are retained properly. When crush starts, it will create a"
			puts "  binding in the scope of an instance of Crush::Box which represents the local machine. "
			puts "  Consider the following command:"
			puts
			puts "    crush> self.class"
			puts "     => Crush::Box"
			puts
			puts "  The 'bash' function provided by crush is actually an instance method of Crush::Box."
			puts "  Since "
		when 'calc'
			puts term_title "Crush as a calculator"
			puts
			puts "  Crush can function as a full scientific calculator. Simply enter an expression and press enter and the "
			puts "  result will be shown."
			puts
			puts "  Crush offers a calculator-focused shell extension which makes some common calculations easier. To import"
			puts "  it, use:"
			puts
			puts "    #{crush}import :calc"
			puts
			puts term_title "Cookbook"
			puts "    Exponents:            2**8                     => 256"
			puts "    Trigonometry:         Math.Sin(Math::PI / 2)   => 1"
			puts "    Hexadecimal:          0x32AC - 0x20B9          => 4595"
			puts "    Octal:                0237 + 044               => 195"
			puts "    Binary:               -0b110101 * 0b100111     => 2067"
			puts "    Minimum:              [ 0, 1, 2, 3 ].min       => 0"
			puts "    Maximum:              [ 0, 1, 2, 3 ].max       => 3"
			puts "    Big numbers:          2**66                    => 73786976294838206464"
			puts "    Modulus:              11 % 2                   => 1"
			puts "    Bitwise AND:          212 & 2342               => 12"
			puts "    Bitwise OR:           212 | 2342               => 2550"
			puts "    Bitwise Exclusive OR: 2 ^ 3                    => 1"
			puts "    Boolean AND:          true and false           => false"
			puts "    Boolean OR:           true or false            => true"
			puts "    View number in hex:   1024.hex                 => \"400\""
			puts "    View quantity in hex: ( 3**3 + 2 ).hex         => \"1d\""
			puts "  "
		when 'bash'
			puts term_title "Running BASH commands"
			puts
			puts "  Unfortunately, the whole world does not yet speak Ruby. For crush to be a useful shell,"
			puts "  it must have an effective and easy to use method for running traditional UNIX commands."
			puts "  Crush has three variants for different scenarios. All three involve invoking the system"
			puts "  shell (typically bash or crash) as a subshell."
			puts 
			puts "  First, when a command entered interactively begins with a dollar followed by a space (\"$ \")"
			puts "  it is treated as a BASH command. No quoting is necessary, and the BASH command line will"
			puts "  continue to the end of the line."
			puts
			puts "    #{crush}$ echo hello"
			puts
			puts "  Full interpolation is available from within the command line string:"
			puts
			puts "    #{crush}foo = #{s}'hello'#{d}"
			puts "    #{crush}$ echo " + '#{foo}'
			puts
			puts "  Caution: If the space after the dollar character is omitted, crush will treat $echo as a"
			puts "  ruby global variable. For the example command we have been using, a syntax error would occur."
			puts "  Mistakes for simpler commands can be more subtle, as in the case of:"
			puts
			puts "    #{crush}$flush    #{Term::DimOn}#=> does not flush!#{Term::DimOff}"
			puts
			puts term_title "BASH commands from crush scripts"
			puts 
			puts "  The $ shortcut is only available from the crush prompt, one cannot make use of"
			puts "  it from scripts. Instead the 'bash' method is provided:"
			puts
			puts "    #{crush}bash #{s}\"echo hello\"#{d}"
			puts
			puts "  The bash method is available on directory objects to support starting the shell with "
			puts "  a different working directory:"
			puts
			puts "    #{crush}home[#{s}'foo/bar/'#{d}].bash #{s}'ls'#{d}   # list ~/foo/bar"
			puts
			puts "  The bash method is also available on box objects, allowing one to execute bash"
			puts "  commands on remote machines."
			puts
			puts "    #{crush}box.bash #{s}'date'#{d}"
			puts
			puts term_title "Capturing the output of commands"
			puts
			puts "  In the methods we've explored so far, the value given to ruby after running the"
			puts "  command is a boolean mapping of the exit code, where zero is true and all other"
			puts "  codes are false. Often it is useful to capture the textual output (stdout) of"
			puts "  a command."
			puts
			puts "    #{crush}output = #{s}`date`#{d}"
			puts "     => \"Wed Sep 29 23:29:29 EDT 2010"
			puts "    ::::\""
			puts
			puts "  Note: the character used is the backtick, not the apostrophe/single quote."
			puts
		when 'paths'
			puts term_title "Paths"
			puts
			puts "  Since crush uses ruby for its basic syntax, specifying paths in crush"
			puts "  is a different experience than on traditional text-based shells like BASH."
			puts "  While it is possible to refer to your files and directories using regular"
			puts "  old string paths, crush offers an object-oriented alternative which has"
			puts "  all the advantages of ruby iterators."
			puts
			puts "  For instance, consider the following BASH command:"
			puts
			puts "    $ cd /usr/bin"
			puts
			puts "  Crush would complain if given this command, because ruby would treat '/usr/'"
			puts "  as a regular expression, and 'bin' as the options for that expression. The "
			puts "  simplest modification to make it work would be to quote the string path."
			puts
			puts "    crush> cd '/usr/bin'"
			puts
			puts "  This however is not idiomatic. Crush offers a fully object-oriented way to"
			puts "  specify paths:"
			puts
			puts "    crush> (root / :usr / :bin).cd"
			puts 
			puts term_title "Whoa, What Is That"
			puts
			puts "  The first part of the expression, '(root/:usr/:bin)' is a division expression."
			puts "  The 'root' variable typically contains a directory object which refers to the '/' or"
			puts "  root directory."
			puts
			puts "  In rush-based shells, dividing a directory object by a string or symbol will yield"
			puts "  an entry object for that file or directory. The :usr and :bin terms are called Symbols"
			puts "  in Ruby parlance. Symbols are a very subtle and nuanced feature, but in many cases you"
			puts "  can replace a string with a symbol if the string starts with an alphabetic character"
			puts "  and consists of only alphanumeric characters and underscores. The same command above"
			puts "  could be written without symbols like so:"
			puts
			puts "    crush> (root / 'usr' / 'bin').cd"
			puts
			puts "  You'll probably want to save your wrist the extra keystroke per term."
			puts
			puts "  Crush offers another method for specifying paths which runs slightly faster:"
			puts
			puts "    crush> (root['usr/bin/']).cd"
			puts
			puts "  Note the trailing slash on the path string. It may be omitted, but if you know"
			puts "  the target is a directory it will generate slightly faster code."
			puts
			puts term_title "Variables: crush has bookmarks"
			puts
			puts "  You have already seen 'root', which specifies a directory object for the root directory."
			puts "  There is also 'home', which points to the current user's home directory. These names are"
			puts "  merely variables and can be overwritten or changed at any time. This also means you can"
			puts "  add more variables for locations that you frequently use."
			puts
			puts "    crush> docs = home / :Documents"
			puts
			puts "  You can stash your variable definitions in a file that crush loads on startup."
			puts "  For more information, see " + term_url(':customizing') + "."
			puts
		when 'license'
			puts term_title "License"
			puts 
			puts "rush, the ruby shell"
			puts "Copyright (C) 2008-2010 Adam Wiggins"
			puts
			puts "crush, bringing rush Closer to UNIX"
			puts "Copyright (C) 2010 William Lahti"
			puts
			puts <<-END
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
			END
		when 'syntax'
			puts term_title "Syntax in crush"
			puts 
			puts "  The syntax used in crush is that of the Ruby programming language,"
			puts "  plus a few simple macro-style additions which make Ruby even "
			puts "  more suited to the role of a command shell."
			puts
			puts "  Obviously knowing Ruby is a great way to feel at home with"
			puts "  crush, but this is not strictly necessary. This help page will"
			puts "  provide an overview of Ruby's syntax for users coming from BASH"
			puts "  or other similar UNIX shells."
			puts
			puts Term::underline("Arguments are separated with " + Term::bold("commas"))
			puts
			puts "  With BASH, one would use the command 'foo' like this:"
			puts
			puts "    $ foo 'Arg1' 'Arg2'"
			puts
			puts "  In crush, arguments are separated by commas, so this would instead be:"
			puts
			puts "    crush> foo 'Arg1', 'Arg2'"
			puts 
			puts "  Technically foo is not a command, it's a " + Term::bold('method') + ". The parentheses are"
			puts "  merely optional:"
			puts
			puts "    crush> foo('Arg1', 'Arg2')"
			puts
			puts "  And each line is not really a command, but an " + Term::bold('expression') + ":"
			puts
			puts "    crush> foo('Arg1', 'Arg2') == foo('Arg1, 'Arg2')"
			puts 
			puts Term::underline("There are only objects, variables and methods")
			puts
			puts "  Methods are like commands. Variables are first-class"
			puts "  citizens in crush, unlike in BASH. And of course, everything"
			puts "  is an object. Variable assignment and reference, big math and"
			puts "  floating point, string manipulation and trigonometry operations"
			puts "  are all available at your finger tips, amongst much, much more."
			puts
			puts "    a = 2 + 2**128	# 2 plus (2 to the 128th power)"
			puts "    echo a			# prints 340282366920938463463374607431768211456"
			puts
			puts "  You don't really need to 'echo' either, crush will usually print the"
			puts "  result of the last line automatically (see " + term_url(":reporter") + "):"
			puts
			puts "    crush> 2 + 4 + 8"
			puts "     => 14"
			puts
			puts "  Classes and objects are very important in crush. These concepts allow"
			puts "  us to create stateful data structures surrounded by useful behaviors."
			puts "  " + Term::bold('Everything') + " is an object. An object's state and"
			puts "  behaviors are accessed using the dot operator ('.')."
			puts
			puts "    crush> 'hello'.start_with? 'h'"
			puts "     => true"
			puts "    crush> 'hello'.start_with? 'w'"
			puts "     => false"
			puts
			puts "  Here we are using the 'start_with?' behavior built-in to String."
			puts "  We haven't mentioned what String is, but one can guess, because"
			puts "  names with capital letters are reserved for class names and constants."
			puts "  Variables on the other hand always start with a lowercase letter or an"
			puts "  underscore."
			puts
			puts "  See " + term_url(":objects") + " for more details."
			puts
			puts Term::underline("Paths must be quoted")
			puts
			puts "  When you want to pass a file path to a method you can usually pass it as"
			puts "  a literal string path or a Dir or File object reference. If you provide"
			puts "  a relative or absolute path string, it must be quoted. "
			puts
			puts "  The following is incorrect and will produce errors in crush:"
			puts "    crush> cd /usr/bin"
			puts "  You must instead put single or double quotes around paths like so:"
			puts "    crush> cd \"/usr/bin\""
			puts "  A more crush-appropriate way to phrase it:"
			puts "    crush> cd root/:usr/:bin"
			puts "  And pure Crush-style:"
			puts "    crush> (root/:usr/:bin).cd"
			puts
			puts "  Some common gotchas: "
			puts "    crush> cd /"
			puts "      Ruby will treat the / character as division, and so it will"
			puts "      defer executing this line until the other side of the division"
			puts "      operation is read from the command line."
			puts "    crush> cd /usr/"
			puts "      Here the " + Term::bold('regular expression') + " /usr/ is passed"
			puts "      to 'cd', which is probably not what you want."
			puts "    crush> cd /usr"
			puts "      You will notice your prompt has now changed. Here '/usr' is treated"
			puts "      as a regular expression with a literal newline in it. Enter another"
			puts "      slash character to restore your prompt and finish the current operation."
			puts "    crush> cd some-dir"
			puts "      Ruby interprets this as: pass the quantity '(value of name some) minus"
			puts "      (value of name dir)' to the cd() method."
			puts
			puts "  See " + term_url(":paths") + " for more details."
			puts
		when 'reporter'
			puts term_title "The crush value reporter"
			puts
			puts "  Normally crush will print the resulting value of an expression entered on the"
			puts "  command line. The component which serializes values on to the screen is known"
			puts "  as the 'reporter'. The default reporter for crush is quite smart, and is fine"
			puts "  for most purposes. It is possible however to swap out, extend, or remove the"
			puts "  reporter entirely."
			puts
			puts "  The reporter summoned by crush is dictated by the " + term_url("shell.reporter")
			puts "  attribute. If " + Term::bold("true") + ", crush's default reporter behavior is used."
			puts "  If " + Term::bold("false") + ", no reporter messages will be shown. If a Proc"
			puts "  is provided, crush will use it in place of the normal reporting behavior. "
			puts "  The default reporter is implemented by the " + Term::bold("shell.report")
			puts "  method."
			puts
			puts term_title "Suppressing the reporter"
			puts
			puts "  In some cases it is useful to suppress the reporter from mentioning an unimportant"
			puts "  value. The default reporter prints nothing when called for the symbol " + Term::bold(":sshh") + "."
			puts "  It is recommended that custom reporters do the same to retain consistency."
			puts
		when 'commandline'
			puts term_title "The crush Command Line"
			puts
			puts "  If any arguments are passed to the crush executable, they are concatenated and"
			puts "  executed, then the shell immediately exits."
			puts
			puts "    $ crush 2 + 2"
			puts "     => 4"
			puts "    $"
			puts
			puts "  If you wish to run some commands then enter interactive mode, just call"
			puts "  shell.run when you're finished:"
			puts
			puts "    $ crush '2 + 2; shell.run'"
			puts "     => 4"
			puts "    crush>"
			puts
		when 'shell.report_collections'
			puts term_title "The 'shell.report_collections' attribute"
			puts
			puts "  #{Term::bold('shell.report_collections')} determines the behavior of the crush value #{term_url(':reporter')} when"
			puts "  dealing with arrays and other types which implement the #{Term::bold('each')} iterator."
		when 'reset'
			puts term_title "The 'reset' function"
			puts
			puts "  Resets the terminal to a pristine, default state. Use if terminal gets wonky."
			puts "  This function just calls the UNIX `reset' command."
			puts
		when 'shell.columns'
			puts term_title "The 'shell.columns' attribute"
			puts
			puts "  The current number of columns in the terminal display. This value can change for"
			puts "  terminal emulators when the window size changes. Some terminals do not support"
			puts "  querying their size. In these cases Crush will use the value of the COLUMNS"
			puts "  environment variable. You can also overwrite the shell.columns attribute,"
			puts "  and your setting will be preserved until you discard it by setting the"
			puts "  attribute to nil. Crush will then continue updating the value automatically."
			puts
		when 'Dir'
			puts term_title "The 'Dir' class"
			puts "class Crush::Dir < Crush::Entry; ...; end;"
			puts
			puts "examples:"
			puts "  usr = Dir.new '/usr'"
			puts "  usr_bin = usr['bin/']"
			puts "  usr_bin.ls"
			puts
			puts "useful methods:"
			puts "  dir.ls             -- print the entries of the directory"
			puts "  dir.path           -- print the parent directory ('/usr' for '/usr/bin')"
			puts "  dir.full_path      -- full, absolute path to directory"
			puts "  dir.name           -- base name of the directory ('bin' for '/usr/bin')"
			puts
			puts "see also:"
			puts "  :File              -- class: represents a file"
			puts "  :cd, :wd, :ls      -- methods: manipulate the working directory"
			puts
			puts "For complete documentation of the Crush::Dir class type:"
			puts "  ri Dir"
		when 'File'
			puts term_title "The 'Dir' class"
			puts "class Crush::Dir < Crush::Entry; ...; end;"
			puts
			puts "examples:"
			puts "  profile = home['.profile']"
			puts "  foo = File.new '/home/liam/.profile'"
			puts
			puts "useful methods:"
			puts "  file.exists?       -- check if the file currently exists"
			puts "  file.contents      -- read the whole file into a string"
			puts "  file.write(str)    -- overwrite the file with the given string"
			puts "  file.access        -- review, test, or modify file access permissions"
			puts
			puts "see also:"
			puts "  :Dir               -- class: represents a directory"
			puts "  :cd, :wd, :ls      -- methods: manipulate the working directory"
			puts
			puts "For complete documentation of the Crush::Dir class type:"
			puts "  ri File"	
		when 'wd'
			puts term_title "The 'wd' command"
			puts "def wd; ...; end;  #=> Crush::Dir"
			puts
			puts "examples:"
			puts "  wd                -- print working dir and store in _ variable"
			puts "  wd['subdir/']     -- obtain Crush::Dir for 'subdir' within working dir"
			puts "  wd.full_path      -- Path to working directory as a String"
			puts "  wd.name           -- Name of the folder (ie, 'bin' for '/usr/bin')"
			puts "  wd.path           -- Parent of working directory (ie, '/usr' for '/usr/bin')"
			puts "  x = wd            -- store working directory in variable x"
			puts
			puts "see also:"
			puts "  :cd               -- method: change working directory"
			puts "  :ls               -- method: list given or current directory"
			puts "  :Dir              -- class: list given or current directory"
			puts
			puts "also known as:"
			puts "  shell.wd"
			puts
			puts "The 'wd' method retrieves the current working directory as an instance of"
			puts "Crush::Dir. The string path may be retrieved via the 'path' attribute."
			puts "The working directory may be changed using the 'cd' command."
			puts
		when 'ls'
			puts term_title "The 'ls' command"
			puts "def ls(dest = '.'); ...; end;  #=> Crush::Dir"
			puts 
			puts "examples:"
			puts "  ls                  -- print contents of current directory"
			puts "  ls '/bin'           -- print contents of the '/bin' directory"
			puts "  root.ls             -- print contents of the '/' (root) directory"
			puts 
			puts "see also:"
			puts "  :wd                 -- method: retrieve current working directory"
			puts "  :cd                 -- method: change working directory"
			puts "  :Dir                -- class: represents a directory"
			puts 
			puts "also known as:"
			puts "  shell.ls"
			puts "  Dir.ls"
			puts
			puts "The 'ls' method prints the entries in the given directory. When no"
			puts "directory path or object is provided, the current working directory"
			puts "is used. See the 'wd' method for determining the working directory."
			puts
		when 'cd'
			puts term_title "The 'cd' command"
			puts "def cd(dest = nil); ...; end;  #=> Crush::Dir"
			puts 
			puts "examples:"
			puts "  cd                -- return to your home directory, same as 'cd home'"
			puts "  cd 'destination'  -- change to the given path, relative to current directory"
			puts "  cd Dir.new('/')   -- change to the given path by Dir object"
			puts
			puts "see also:"
			puts "  :wd               -- method: retrieve current working directory"
			puts "  :ls               -- method: list given or current directory"
			puts "  :Dir              -- class: represents a directory"
			puts 
			puts "also known as:"
			puts "  chdir"
			puts "  shell.cd"
			puts "  shell.chdir"
			puts
			puts "The 'cd' method changes the working directory associated with the current"
			puts "instance of crush."
			puts 
		when 'prompt'
			puts term_title "Prompting in crush"
			puts
			puts "  One feature which is curiously missing in the rush shell is "
			puts "  the ability to customize one's prompt. Crush has brought back"
			puts "  shell prompt customization with a vengeance!"
			puts
			puts "  Most simply, set your prompt using:"
			puts "    shell.prompt = \"brush> \""
			puts
			puts "  If the object in shell.prompt implements the 'call' method"
			puts "  (such as a Proc), that method will be called, passing"
			puts "  the shell object as the first parameter. The result will be"
			puts "  printed as the prompt. For example, the same prompt above in"
			puts "  a Proc might be:"
			puts
			puts "    shell.prompt = proc { \"brush> \" }"
			puts
			puts "  For more interesting prompts, use the shell object passed as"
			puts "  the parameter:"
			puts
			puts "    shell.prompt = proc do |shell|"
			puts "      if shell.indent_level > 0"
			puts '         "   #{shell.indent_level}> "'
			puts "      else"
			puts '         "crush> "'
			puts "    end"
			puts 
			puts "  Other values useful for prompting:"
			puts "   - shell.quoted  #=> String, the active quote character or nil if none"
			puts "   - shell.wd      #=> Crush::Dir, the current working directory"
			puts "   - box.user      #=> The user who is logged in"
			puts "   - box.host      #=> The hostname of the machine crush is running on"
		when 'loops'
			puts term_title "Looping and Iterating"
			puts
			puts "  Most looping operations are defined in terms of " + Term::bold('iterators') + ","
			puts "  which in Ruby parlance are methods which take code as part of their input."
			puts "  Ruby has non-iterator style looping as well, but they should be used only"
			puts "  when you cannot express the loop using iterators. You will generally find"
			puts "  almost any loop can be expressed using Ruby's powerful iterators."
			puts
			puts term_title "times: The simplest iterator and how to give it code"
			puts
			puts "  So when using an iterator, one provides a block of code which will be executed"
			puts "  zero or more times by the iterator method. The iterator can pass parameters to the"
			puts "  code block as well. An example:"
			puts
			puts "    crush> 5.times { |x| puts x }"
			puts "    0"
			puts "    1"
			puts "    2"
			puts "    3"
			puts "    4"
			puts "     => 5"
			puts
			puts "  The code within the curly braces was run five times, with x as 0, then 1, 2, 3, and 4."
			puts "  One can see that the " + Term::bold('n.times') + " iterator simply performs n loops. "
			puts
			puts term_title "each: Iteration becomes enumeration"
			puts
			puts "  Sequence and collection types such as arrays and ranges define the " + Term::bold("each")
			puts "  iterator."
			puts
			puts "    crush> [0, 2, 4, 8].each { |x| puts x }"
			puts "    0"
			puts "    2"
			puts "    4"
			puts "    8"
			puts "     => 4 x Fixnum"
			puts
			puts "  The expression '[0, 2, 4, 8]' constructs an array of four elements. Applying the each method"
			puts "  to this array caused the associated code block to be run four times, one for each element of the"
			puts "  array."
		when 'ri'
			puts term_title "Using ri (Ruby Information) from crush"
			puts
			puts "Crush has a built-in `ri' command which summons the system's Ruby"
			puts "Information (ri) tool directly. This page describes some pitfalls users "
			puts "commonly face when using ri via crush."
			puts
			puts " - " + term_title("Strings versus Symbols versus Classes and Modules")
			puts "   Note the differences in the following commands:"
			puts "     * ri  'File'"
			puts "       ri  :File"
			puts "       ri ::File  -- shows the ::File class documentation (Ruby standard)"
			puts "     * ri   File  -- shows the Crush::File class documentation"
			puts
			puts "   In the last case crush takes the to_s of the current "
			puts "   File class, which in rush-based shells is 'Crush::File' not the Ruby"
			puts "   standard File class. You can always access standard classes with the"
			puts "   global scope operator (::) like '::File' or '::Dir'."
			puts
		else
			puts "unknown topic '#{topic}'"
		end
		puts
	end
end
