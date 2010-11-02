require File.dirname(__FILE__) + '/base'

describe Crush::EmbeddableShell do
	before do
		@shell = Crush::EmbeddableShell.new
	end

	it "should execute unknown methods against a Crush::Shell instance" do
		@shell.root.class.should == Crush::Dir
	end
	
	it "should executes a block as if it were inside the shell" do
		@shell.execute_in_shell {
			root.class.should == Crush::Dir
		}
	end
end
