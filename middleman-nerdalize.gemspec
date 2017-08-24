# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
	s.name        = 'middleman-nerdalize'
	s.version     = '0.0.2'
	s.platform    = Gem::Platform::RUBY
	s.authors     = ['Alexander Weiss']
	s.email       = ['ik@alexanderweiss.nl']
	s.homepage    = 'https://github.com/nerdalize/middleman-nerdalize'
	s.summary     = 'A bundle of extensions for Middleman used across Nerdalize sites.'
	# s.description = %q{A longer description of your extension}

	s.files         = `git ls-files`.split("\n")
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
	s.require_paths = ["lib"]

	# The version of middleman-core your extension depends on
	s.add_runtime_dependency("middleman-core", [">= 4.2.1"])

	# Additional dependencies
	s.add_runtime_dependency("nokogiri", ">= 1.8.0")
	s.add_runtime_dependency("html-proofer", ">= 3.7.2")
	s.add_runtime_dependency("kramdown", ">= 1.14.0")
end
