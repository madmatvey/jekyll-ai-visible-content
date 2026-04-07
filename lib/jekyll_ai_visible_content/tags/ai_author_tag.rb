# frozen_string_literal: true

module JekyllAiVisibleContent
  module Tags
    class AiAuthorTag < Liquid::Tag
      def render(context)
        site = context.registers[:site]
        config = JekyllAiVisibleContent.config(site)
        return '' unless config.enabled?

        entity = config.entity
        return '' unless entity['name']

        parts = []
        parts << %(<span itemprop="author" itemscope itemtype="https://schema.org/Person">)
        parts << %(  <a itemprop="url" href="#{config.site_url}/about/">)
        parts << %(    <span itemprop="name">#{entity['name']}</span>)
        parts << %(  </a>)
        parts << %(</span>)
        parts.join("\n")
      end
    end
  end
end

Liquid::Template.register_tag('ai_author', JekyllAiVisibleContent::Tags::AiAuthorTag)
