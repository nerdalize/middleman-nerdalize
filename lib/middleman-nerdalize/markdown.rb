require 'middleman-core'
require 'kramdown/parser/kramdown'

module MiddlemanNerdalize

	# Extension namespace
	class Markdown < ::Middleman::Extension

		def initialize(app, options_hash={}, &block)
			# Call super to build options from the options_hash
			super

		end

		def after_configuration

			# Set markdown to use our custom Kramdown parser.
			app.config[:markdown][:input] = KramdownParser

		end

		helpers do
			# Markdown helper to render markdown to HTML
			def markdown(source, **locals)
				context = @app.template_context_class.new(self, locals)
				# TODO: Figure out how and why the context gets into the config and if what we're doing here makes senses.
				Tilt['markdown'].new(app.config.markdown.except :context) {source}.render(context)
			end
		end

		# Custom Kramdown parser with various additions
		class KramdownParser < ::Kramdown::Parser::Kramdown

			def initialize(source, options)
				super
				@block_parsers.unshift(:string_interpolation)
			end

			# TODO: This regex should be improved.
			STRING_INTERPOLATION_START = /#\{.*?\}/

			# Support string interpolation at the start of a line.
			def parse_string_interpolation
				@src.pos += @src.matched_size
				@tree.children << Element.new(:raw, @src.matched)
			end

			define_parser(:string_interpolation, STRING_INTERPOLATION_START)

			# Override blockquote to turn the last element into a footer.
			def parse_blockquote
				start_line_number = @src.current_line_number
				result = @src.scan(PARAGRAPH_MATCH)
				while !@src.match?(self.class::LAZY_END)
					last_pos = @src.save_pos
				  result << @src.scan(PARAGRAPH_MATCH)
				end
				result.gsub!(BLOCKQUOTE_START, '')

				# Turn the last line into a footer if prefixed with --.
				if (result.lines[-1].match(/^--\s*(.*)$/))
					footer = new_block_el(:html_element, 'footer', nil, :category => :block, :content_model => :span)
					# Parse the footer content as a block and then take out the root of the children.
					# TODO: This is a hack, because I couldn't get parse_spans to work.
					parse_blocks(footer, result.lines[-1].gsub(/^--\s*(.*)$/, '\1'))
					footer.children = footer.children[0].children
					result = result.lines[0..-2].join('\n')
				end

				el = new_block_el(:blockquote, nil, nil, :location => start_line_number)
				@tree.children << el
				parse_blocks(el, result)
				el.children << footer if footer
				true
			end

			# Override image element to use figure when title is set.
			def add_link(el, href, title, alt_text = nil, ial = nil)
				if el.type != :img || !title
					super
					return
				end

				el.options[:ial] = ial
				update_attr_with_ial(el.attr, ial) if ial
				el.attr['src'] = href
				el.attr['alt'] = alt_text
				el.children.clear
				figure = Element.new(:html_element, 'figure', nil, :category => :block, :content_model => :block)
				caption = Element.new(:html_element, 'figcaption', nil, :category => :span, :content_model => :block)
				caption.children << Element.new(:text, title)

				figure.children << el << caption

				@tree.children << figure
			end

			def handle_extension(name, opts, body, type, line_no = nil)
				return true if name == 'comment'
				return true if super != false

				case name
				when 'blog_story_footer'

					footer = new_block_el(:html_element, 'footer', :class => 'action', :category => :block, :content_model => :block)
					footer.children << Element.new(:text, opts['text'] + ' ')

					if opts['link'] != nil && opts['button'] != nil
						link = Element.new(:a, nil, {'href' => opts['link']})
						link.children << Element.new(:text, opts['button'])
						if opts['style'] == 'button'
							link.attr['class'] = 'btn'
						else
							link.attr['class'] = 'arrow-link'
							link.children << Element.new(:raw, ' <svg width="12" height="12" viewBox="0 0 12 12" stroke-width="2" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round"><title>Right arrow</title><polyline stroke-linejoin="round" points="6.5 2 10 6 6.5 10"/><path d="M2 6h7"/></svg>')
						end
						footer.children << link
					end

					@tree.children << footer

					true
				else
					false
				end
			end

		end

	end

end