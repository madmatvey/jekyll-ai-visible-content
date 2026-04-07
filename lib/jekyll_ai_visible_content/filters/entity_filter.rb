# frozen_string_literal: true

module JekyllAiVisibleContent
  module Filters
    module EntityFilter
      def ai_entity_name(input)
        site = @context.registers[:site]
        config = JekyllAiVisibleContent.config(site)
        config.entity["name"] || input
      end

      def ai_entity_id(input)
        site = @context.registers[:site]
        config = JekyllAiVisibleContent.config(site)
        config.entity_id || input
      end

      def ai_entity_url(entity_name)
        site = @context.registers[:site]
        config = JekyllAiVisibleContent.config(site)
        registry = Entity::Registry.new(config)
        definition = registry.find_entity_by_name(entity_name)
        definition ? definition["url"] : "#"
      end
    end
  end
end

Liquid::Template.register_filter(JekyllAiVisibleContent::Filters::EntityFilter)
