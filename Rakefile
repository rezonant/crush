require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('crush', '1.1.0') do |s|
	s.summary = "The Comprehensive Ruby Shell"
	s.description = "A complete Ruby shell originally based on Rush by Adam Wiggins. Provides a fully featured interactive shell and a library.  Manage both local and remote unix systems from a single client."
	s.url = "http://github.com/rezonant/crush"
	s.author = "William Lahti (originally by Adam Wiggins)"
	p.ignore_pattern = ["tmp/*", "script/*", "*.bak", "*.swp", "*~"]
	s.email = "wilahti@gmail.com"
	p.development_dependencies = []
	s.runtime_dependencies = ['session']	
end

require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc", "--dry-run"]
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
	t.rcov = true
	t.rcov_opts = ['--exclude', 'examples']
end

task :default => :spec

######################################################

require 'rake/rdoctask'

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'rdoc'
	t.title    = "crush, the comprehensive Ruby shell"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('README.rdoc')
	t.rdoc_files.include('lib/crush.rb')
	t.rdoc_files.include('lib/crush/*.rb')
end

