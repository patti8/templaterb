   # app/helpers/markdown_helper.rb

   module MarkdownHelper
    def render_markdown(text)
      renderer = Redcarpet::Render::HTML.new
      markdown = Redcarpet::Markdown.new(renderer, extensions = {})
      markdown.render(text).html_safe
    end
  end
