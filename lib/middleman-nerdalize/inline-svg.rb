require 'middleman-core'

module MiddlemanNerdalize

	class InlineSVG < Middleman::Extension

		def initialize(app, options_hash={}, &block)
			# Call super to build options from the options_hash
			super

			require 'nokogiri'

		end

		def after_configuration
			app.use Middleware, middleman_app: app
		end

		helpers do
			def icon(path, inline: false, color: nil)

				path_parts = path.split('/')
				class_name = 'icon ' + path_parts.map { |part| "#{part}-icon" }.join(' ')

				style = "color: #{color};" if color

				if inline == true
					svg("icons/#{path}", style: style, class: class_name)
				else
					"<svg class=\"#{class_name}\" role=\"img\"#{style ? "style=\"#{style}\"" : ''}><use xlink:href=\"#icons/#{path}\"></use></svg>"
				end
			end

			def svg(name, symbols: false, **attributes)

				path = name =~ /\.svg$/ ? name : "images/#{name}.svg"
				resource = sitemap.find_resource_by_path(path)

				raise("SVG file #{path} missing") if resource == nil

				# Load file and clean XML tag.
				content = File.read(resource.source_file)
				content.gsub!(/(<\?xml.*?>|<!DOCTYPE.*?>)/, '')

				# Parse SVG tag and add/replace any attributes.

				svg_tag_string = content.match(/(<svg.*?>)/)[0].gsub(/(xmlns.*?=".*?")/, '')
				svg_tag = Nokogiri::XML.fragment(svg_tag_string)

				if symbols == true
					attributes[:width] = 0
					attributes[:height] = 0
					attributes[:class] = 'symbols'
				end

				attributes.each do |attribute, value|
					svg_tag.children[0][attribute.id2name] = value
				end

				# Prefix ID's and references (unless this is a symbols file)
				if symbols == false

					prefix = path.rpartition('.').first.gsub(/^\//, '').gsub(/\//, '-') + '-'

					# Gather all defined ID's (using id="") and add the prefix.
					ids = []
					content.gsub!(/(?<=id=")(.*?)(?=")/) do |id|
						ids << id
						prefix + id
					end

					# Add the prefix to all references to the found id.
					ids.each do |id|
						content.gsub!(/\##{Regexp.escape(id)}/, '#' + prefix + id)
					end

				end

				# Turn back into a nice string.
				content.gsub!(/(<svg.*?>)/x, svg_tag.to_html.gsub('</svg>', ''))
			end
		end

		class Middleware

			def initialize(app, options = {})
				@rack_app = app
				@middleman_app = options[:middleman_app]
			end

			# Call code from middleman-protect-emails (https://github.com/amsardesai/middleman-protect-emails)
			def call(env)
				status, headers, response = @rack_app.call(env)

				# Get path
				path = ::Middleman::Util.full_path(env['PATH_INFO'], @middleman_app)

				# Match only HTML documents
				if path =~ /(^\/$)|(\.(htm|html)$)/
					body = ::Middleman::Util.extract_response_text(response)
					if body
						status, headers, response = Rack::Response.new(rewrite_response(body), status, headers).finish
					end
				end

				[status, headers, response]
			end

			def rewrite_response(body)

				# Gather all defs sections.
				defs = []
				output = body.gsub(/<defs[^\/]*?>(.*?)<\/defs>/m) do |m|
					defs << $1
					''
				end

				return body if defs.length == 0

				# Parse defs sections using Nokogiri.
				defs_doc = Nokogiri::XML("<defs>#{defs.join('')}</defs>") do |config|
				  config.strict.noblanks
				end

				# Remove duplicates (same id).
				# TODO: Make smarter: actually check contents too.
				defs_node = defs_doc.at_css('defs')
				defs_node.children.group_by { |element| element['id'] }.each do |id, elements|
					elements.drop(1).each { |el| el.remove }
				end

				# Add to the body.
				output.sub!(/<defs\/>/, defs_node.to_xml)

			end

		end

	end

end