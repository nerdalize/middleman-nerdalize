require 'middleman-core'
require 'html-proofer'

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
			ENV['CONTEXT'] ||= 'test'
			ENV['DEPLOY_PRIME_URL'] ||= 'https://www.nerdalize.com'

			# TODO: Pass valid options to build.
			invoke Middleman::Cli::Build, [], { verbose: options['verbose'] }

			HTMLProofer.check_directory("./build",
				disable_external: !options['external-links'],
				check_html: true,
				empty_alt_ignore: true,
				url_ignore: [/^#email-protection.*/, /^\/blog\/.*(#en|#nl)/, /(http)?s?:\/\/(www.)?linkedin.com.*/],
				internal_domains: ['www.nerdalize.com']
			).run
		end

		# Add to CLI
		Base.register(self, 'test', 'test [options]', 'Build & validate')
		Base.map('t' => 'test')

	end
end