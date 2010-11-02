require File.dirname(__FILE__) + '/base'

describe Crush do
	it "fetches a local file path" do
		Crush['/etc/hosts'].full_path.should == '/etc/hosts'
	end

	it "fetches the dir of __FILE__" do
		Crush.dir(__FILE__).name.should == 'spec'
	end

	it "fetches the launch dir (aka current working directory or pwd)" do
		Dir.stub!(:pwd).and_return('/tmp')
		Crush.launch_dir.should == Crush::Box.new['/tmp/']
	end

	it "runs a bash command" do
		Crush.bash('echo hi').should == "hi\n"
	end

	it "gets the list of local processes" do
		Crush.processes.should be_kind_of(Crush::ProcessSet)
	end

	it "gets my process" do
		Crush.my_process.pid.should == Process.pid
	end
end
