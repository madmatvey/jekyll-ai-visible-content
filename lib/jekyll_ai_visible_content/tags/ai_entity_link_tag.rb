# frozen_string_literal: true

module JekyllAiVisibleContent
  module Tags
    class AiEntityLinkTag < Liquid::Tag
      SYNTAX = /\A\s*"([^"]+)"\s*\z/

      def initialize(tag_name, markup, tokens)
        super
        match = markup.match(SYNTAX)
        @entity_name = match ? match[1] : markup.strip.delete('"')
      end

      def render(context)
        site = context.registers[:site]
        config = JekyllAiVisibleContent.config(site)
        return @entity_name unless config.enabled?

        registry = Entity::Registry.new(config)
        definition = registry.find_entity_by_name(@entity_name)

        if definition
          url = definition["url"]
          build_link(url, @entity_name)
        else
          @entity_name
        end
      end

      private

      def build_link(url, name)
        %(<a href="#{url}" itemprop="about" itemscope itemtype="https://schema.org/Thing">) +
          %(<span itemprop="name">#{name}</span></a>)
      end
    end
  end
end

Liquid::Template.register_tag("ai_entity_link", JekyllAiVisibleContent::Tags::AiEntityLinkTag)
