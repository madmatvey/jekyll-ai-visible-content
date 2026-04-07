# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class WebsiteSchema
      attr_reader :config, :registry

      def initialize(config, registry)
        @config = config
        @registry = registry
      end

      def build
        data = {
          "@type" => "WebSite",
          "@id" => "#{config.site_url}/#website",
          "url" => config.site_url,
          "name" => config.site_title,
          "description" => config.site_description&.strip,
          "publisher" => registry.primary_entity_ref
        }

        append_search_action(data)
        data.compact
      end

      private

      def append_search_action(data)
        search_url = "#{config.site_url}/search?q={search_term_string}"
        data["potentialAction"] = {
          "@type" => "SearchAction",
          "target" => search_url,
          "query-input" => "required name=search_term_string"
        }
      end
    end
  end
end
