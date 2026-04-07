# frozen_string_literal: true

module JekyllAiVisibleContent
  module Entity
    class Registry
      attr_reader :config, :primary_entity, :topic_entities

      def initialize(config)
        @config = config
        @primary_entity = build_primary_entity
        @topic_entities = build_topic_entities
        @mention_counts = Hash.new(0)
        @entity_pages = Hash.new { |h, k| h[k] = [] }
      end

      def primary_entity_hash
        @primary_entity_hash ||= primary_entity&.to_hash
      end

      def primary_entity_ref
        return nil unless config.entity_id

        { '@type' => config.entity_type, '@id' => config.entity_id }
      end

      def record_mention(entity_name, page_url)
        normalized = normalize_name(entity_name)
        @mention_counts[normalized] += 1
        @entity_pages[normalized] << page_url unless @entity_pages[normalized].include?(page_url)
      end

      def mention_count(entity_name)
        @mention_counts[normalize_name(entity_name)]
      end

      def pages_for(entity_name)
        @entity_pages[normalize_name(entity_name)]
      end

      def all_mentions
        @mention_counts.dup
      end

      def topic_url(topic_name)
        slug = normalize_name(topic_name).gsub(/\s+/, '-')
        "/topics/#{slug}/"
      end

      def entity_definitions
        defs = config.linking['entity_definitions'] || {}
        knows = config.entity['knows_about'] || []

        knows.each_with_object(defs.dup) do |topic, result|
          slug = normalize_name(topic).gsub(/\s+/, '-')
          next if result.key?(slug)

          result[slug] = {
            'name' => topic,
            'url' => topic_url(topic),
            'description' => nil
          }
        end
      end

      def find_entity_by_name(name)
        normalized = normalize_name(name)
        entity_definitions.values.find { |d| normalize_name(d['name']) == normalized }
      end

      private

      def build_primary_entity
        return nil unless config.entity['name']

        case config.entity_type
        when 'Person'
          Person.new(config)
        when 'Organization'
          Organization.new(config)
        end
      end

      def build_topic_entities
        (config.entity['knows_about'] || []).map do |topic|
          { 'name' => topic, 'slug' => normalize_name(topic).gsub(/\s+/, '-') }
        end
      end

      def normalize_name(name)
        name.to_s.strip.downcase
      end
    end
  end
end
