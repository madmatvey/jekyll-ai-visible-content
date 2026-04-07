# frozen_string_literal: true

module JekyllAiVisibleContent
  module EntityClassifier
    RELEVANCE_FRONT_MATTER = 3
    RELEVANCE_TITLE = 2
    RELEVANCE_BODY = 1

    class << self
      def classify_page(doc, config)
        max = config.ai_resources['max_links_per_page'] || 5
        entities = []

        add_primary_entity(entities, doc, config)
        add_front_matter_topics(entities, doc, config)
        add_detected_topics(entities, doc, config)
        add_organization(entities, doc, config)
        add_general_topic_fallback(entities, doc)

        entities
          .uniq { |e| e[:slug] }
          .sort_by { |e| -e[:relevance] }
          .first(max)
      end

      def slugify(name)
        name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/(^-|-$)/, '')
      end

      private

      def add_primary_entity(entities, doc, config)
        return unless config.entity['name']

        is_person_page = doc.data['entity_type']&.downcase == 'person' ||
                         doc.url.to_s.match?(%r{/about/?$})

        return unless is_person_page

        entities << {
          type: config.entity_type.downcase == 'organization' ? 'entity' : 'person',
          slug: slugify(config.entity['id_slug'] || config.entity['name']),
          name: config.entity['name'],
          relevance: RELEVANCE_FRONT_MATTER + 1
        }
      end

      def add_front_matter_topics(entities, doc, _config)
        topics = doc.data['topics']
        return unless topics.is_a?(Array)

        topics.each do |topic|
          entities << {
            type: 'topic',
            slug: slugify(topic),
            name: topic,
            relevance: RELEVANCE_FRONT_MATTER
          }
        end
      end

      def add_detected_topics(entities, doc, config)
        known_topics = config.entity['knows_about'] || []
        return if known_topics.empty?

        title = (doc.data['title'] || '').downcase
        description = (doc.data['description'] || '').downcase
        body = (doc.content || '').downcase

        known_topics.each do |topic|
          needle = topic.downcase
          relevance = if title.include?(needle) || description.include?(needle)
                        RELEVANCE_TITLE
                      elsif body.include?(needle)
                        RELEVANCE_BODY
                      end
          next unless relevance

          entities << { type: 'topic', slug: slugify(topic), name: topic, relevance: relevance }
        end
      end

      def add_organization(entities, doc, config)
        works_for = config.entity['works_for']
        return unless works_for.is_a?(Hash) && works_for['name']

        text = "#{doc.data['title']} #{doc.data['description']} #{doc.content}".downcase
        return unless text.include?(works_for['name'].downcase)

        entities << {
          type: 'entity',
          slug: slugify(works_for['name']),
          name: works_for['name'],
          relevance: RELEVANCE_BODY
        }
      end

      def add_general_topic_fallback(entities, doc)
        return unless entities.empty?

        slug = slugify(doc.url.to_s.split('/').reject(&:empty?).last)
        title = doc.data['title'].to_s.strip

        slug = slugify(title) if slug.empty?
        return if slug.empty?

        name = if title.empty?
                 slug.tr('-', ' ').split.map(&:capitalize).join(' ')
               else
                 title
               end

        entities << {
          type: 'topic',
          slug: slug,
          name: name,
          relevance: RELEVANCE_BODY
        }
      end
    end
  end
end
