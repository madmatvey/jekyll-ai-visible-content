# frozen_string_literal: true

module JekyllAiVisibleContent
  module Generators
    class EntityMapGenerator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        config = JekyllAiVisibleContent.config(site)
        return unless config.enabled?

        registry = Entity::Registry.new(config)
        scan_content(site, registry, config)

        content = build_entity_map(config, registry)
        page = Jekyll::PageWithoutAFile.new(site, site.source, '', 'entity-map.json')
        page.content = content
        page.data['layout'] = nil
        page.data['sitemap'] = false
        site.pages << page
      end

      private

      def scan_content(site, registry, config)
        all_docs = site.posts.docs + site.pages
        entity_names = (config.entity['knows_about'] || []) + [config.entity['name']].compact

        all_docs.each do |doc|
          text = (doc.content || '').downcase
          page_url = doc.url

          entity_names.each do |name|
            registry.record_mention(name, page_url) if text.include?(name.downcase)
          end
        end
      end

      def build_entity_map(config, registry)
        primary = {
          'id' => config.entity_id,
          'type' => config.entity_type,
          'name' => config.entity['name'],
          'source_pages' => registry.pages_for(config.entity['name'] || ''),
          'total_references' => registry.mention_count(config.entity['name'] || '')
        }

        topics = (config.entity['knows_about'] || []).map do |topic|
          {
            'name' => topic,
            'mentions' => registry.mention_count(topic),
            'linked_posts' => registry.pages_for(topic)
          }
        end

        JSON.pretty_generate(
          'primary_entity' => primary,
          'entities' => topics,
          'generated_at' => Time.now.iso8601
        )
      end
    end
  end
end
