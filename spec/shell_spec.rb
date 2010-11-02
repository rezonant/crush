require File.dirname(__FILE__) + '/base'
require 'crush/shell'

describe Crush::Shell do
	before do
		@shell = Crush::Shell.new
	end

	it "matches open path commands for readline tab completion" do
		@shell.path_parts("dir['app").should == [ "dir", "[", "'", "app", "" ]
		@shell.path_parts('dir/"app').should == [ "dir", "/", '"', "app", "" ]
	end

	it "matches open path commands on globals for readline tab completion" do
		@shell.path_parts("$dir['app").should == [ "$dir", "[", "'", "app", "" ]
		@shell.path_parts('$dir/"app').should == [ "$dir", "/", '"', "app", "" ]
	end

	it "matches open path commands on instance vars for readline tab completion" do
		@shell.path_parts("@dir['app").should == [ "@dir", "[", "'", "app", "" ]
		@shell.path_parts('@dir/"app').should == [ "@dir", "/", '"', "app", "" ]
	end
end
