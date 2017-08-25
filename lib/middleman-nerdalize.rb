require "middleman-core"

Middleman::Extensions.register :nerdalize_markdown do
	require "middleman-nerdalize/markdown"
	MiddlemanNerdalize::Markdown
end

Middleman::Extensions.register :inline_svg do
	require "middleman-nerdalize/inline-svg"
	MiddlemanNerdalize::InlineSVG
end

Middleman::Extensions.register :nerdalize do
	require "middleman-nerdalize/extension"
	MiddlemanNerdalize::Extension
end

Middleman::Extensions.register :html_proofer do
	require "middleman-nerdalize/html-proofer"
	MiddlemanNerdalize::HTMLProofer
end
