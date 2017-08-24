require 'middleman-core'

module MiddlemanNerdalize

	# Extension namespace
	class Extension < ::Middleman::Extension

		helpers do

			def strip_html(string)
				# Strip all HTML, including character references (turning them into the actual character).
				Nokogiri::HTML.fragment(string).text
			end

			def fastimage(path)
				# Get full image path.
				# TODO: Handle remote images?
				image = sitemap.find_resource_by_path(path)
				path = image.source_file if image

				FastImage.new(path, raise_on_failure: true)
			end

		end

	end

end