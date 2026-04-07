# frozen_string_literal: true

module JekyllAiVisibleContent
  module Entity
    class Organization
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def to_hash
        entity = config.entity
        data = {
          '@type' => 'Organization',
          '@id' => config.entity_id,
          'name' => entity['name'],
          'url' => config.site_url
        }

        append_image(data, entity)
        append_description(data, entity)
        append_address(data, entity)
        append_same_as(data, entity)

        data.compact
      end

      private

      def append_image(data, entity)
        return unless entity['image']

        url = absolute_url(entity['image'])
        data['logo'] = {
          '@type' => 'ImageObject',
          'url' => url
        }
      end

      def append_description(data, entity)
        data['description'] = entity['description']&.strip if entity['description']
      end

      def append_address(data, entity)
        loc = entity['location']
        return unless loc && (loc['locality'] || loc['country'])

        data['address'] = {
          '@type' => 'PostalAddress',
          'addressLocality' => loc['locality'],
          'addressCountry' => loc['country']
        }.compact
      end

      def append_same_as(data, entity)
        links = entity['same_as']
        data['sameAs'] = links if links&.any?
      end

      def absolute_url(path)
        return path if path&.start_with?('http')

        "#{config.site_url}#{path}"
      end
    end
  end
end
