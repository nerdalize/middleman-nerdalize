require 'middleman-core'
require 'middleman-core/cli'
require 'html-proofer'

module MiddlemanNerdalize

	# Extension namespace
	class HTMLProofer < ::Middleman::Extension

		def initialize(app, options_hash={}, &block)
			# Call super to build options from the options_hash
			super app, {}, &block

			if !defined? MiddlemanNerdalize::HTMLProofer::Options
				MiddlemanNerdalize::HTMLProofer.const_set('Options', options_hash)
			end

		end

	end

end

module Middleman::Cli

	# This class provides a "test" command for the middleman CLI.
	class Test < Thor::Group
		include Thor::Actions

		check_unknown_options!

		class_option 'external-links',
			type: :boolean,
			default: true,
			desc: 'Check external links (--no-external-links to disable)'

		class_option 'verbose',
			type: :boolean,
			default: false,
			desc: 'Build using verbose option'

		namespace :test

		# Tell Thor to exit with a nonzero exit code on failure
		def self.exit_on_failure?
			true
		end

		def test

			if !defined? MiddlemanNerdalize::HTMLProofer::Options
				puts "HTML Proofer isn't activated in config.rb. Therefore the test command isn't enabled."
				exit 1
			end

			proofer_options = ::MiddlemanNerdalize::HTMLProofer::Options.dup
			proofer_options[:disable_external] = true if !options['external-links']

			ENV['CONTEXT'] ||= 'test'
			if proofer_options.has_key?(:internal_domains)
				ENV['DEPLOY_PRIME_URL'] ||= "https://#{proofer_options[:internal_domains].first}"
			end

			# TODO: Pass valid options to build.
			invoke Middleman::Cli::Build, [], { verbose: options['verbose'] }

			HTMLProofer.check_directory("./build", proofer_options).run
		end

		# Add to CLI
		Base.register(self, 'test', 'test [options]', 'Build & validate')
		Base.map('t' => 'test')

	end
end