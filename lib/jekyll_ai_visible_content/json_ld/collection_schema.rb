# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class CollectionSchema
      attr_reader :config, :page, :items

      def initialize(config, page, items)
        @config = config
        @page = page
        @items = items
      end

      def build
        return nil unless items&.any?

        {
          "@type" => "CollectionPage",
          "name" => page.data["title"],
          "description" => page.data["description"],
          "url" => absolute_url(page.url),
          "mainEntity" => {
            "@type" => "ItemList",
            "itemListElement" => items.each_with_index.map { |item, i| list_item(item, i) }
          }
        }.compact
      end

      private

      def list_item(item, index)
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "url" => absolute_url(item.url),
          "name" => item.data["title"]
        }.compact
      end

      def absolute_url(path)
        return path if path&.start_with?("http")

        "#{config.site_url}#{path}"
      end
    end
  end
end
