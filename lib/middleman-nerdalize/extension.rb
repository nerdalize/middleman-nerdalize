require 'middleman-core'

module MiddlemanNerdalize

	# Extension namespace
	class Extension < ::Middleman::Extension

		def initialize(app, options_hash={}, &block)
			# Call super to build options from the options_hash
			super

			require 'nokogiri'

		end

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
			
			def resource_for(path_or_resource, options={})
				# Get resource for a path, similar to url_for, but returning a resource rather than a url.
				# NOTE: Most code is copied from the built-in url_for at https://github.com/middleman/middleman/blob/79c39b5d880adcb6711cfb2b149ea79ffc29ffd5/middleman-core/lib/middleman-core/util/paths.rb#L152
			
				if path_or_resource.is_a?(::Middleman::Sitemap::Resource)
					return resource
				end
				
				if path_or_resource.is_a?(String) || path_or_resource.is_a?(Symbol)
					r = app.sitemap.find_resource_by_page_id(path_or_resource)
					
					path_or_resource = r ? r : path_or_resource.to_s
				end
				
				# Handle Resources and other things which define their own url method
				url = if path_or_resource.respond_to?(:url)
					path_or_resource.url
				else
					path_or_resource.dup
				end
				
				# Try to parse URL
				begin
					uri = ::Middleman::Util.parse_uri(url)
				rescue ::Addressable::URI::InvalidURIError
					# Nothing we can do with it, it's not really a URI
					return
				end
				
				if path_or_resource.is_a?(::Middleman::Sitemap::Resource)
					resource = path_or_resource
					resource_url = url
				elsif current_resource && uri.path && !uri.host
					# Handle relative urls
					url_path = Pathname(uri.path)
					current_source_dir = Pathname('/' + current_resource.path).dirname
					url_path = current_source_dir.join(url_path) if url_path.relative?
					resource = app.sitemap.find_resource_by_path(url_path.to_s)
					if !resource
						# Try to find a resource relative to destination paths
						url_path = Pathname(uri.path)
						current_source_dir = Pathname('/' + current_resource.destination_path).dirname
						url_path = current_source_dir.join(url_path) if url_path.relative?
						resource = app.sitemap.find_resource_by_destination_path(url_path.to_s)
					end
				end
				
				resource
				
			end

		end

	end

end