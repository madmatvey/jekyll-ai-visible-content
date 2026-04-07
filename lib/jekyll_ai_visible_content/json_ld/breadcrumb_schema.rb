# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class BreadcrumbSchema
      attr_reader :config, :page

      def initialize(config, page)
        @config = config
        @page = page
      end

      def build
        items = build_items
        return nil if items.size < 2

        {
          '@type' => 'BreadcrumbList',
          'itemListElement' => items
        }
      end

      private

      def build_items
        url = page.respond_to?(:url) ? page.url : '/'
        segments = url.to_s.split('/').reject(&:empty?)

        items = [list_item(1, 'Home', "#{config.site_url}/")]

        path = ''
        segments.each_with_index do |segment, idx|
          path = "#{path}/#{segment}"
          position = idx + 2
          name = humanize(segment)

          items << if idx == segments.size - 1
                     list_item_no_url(position, page.data['title'] || name)
                   else
                     list_item(position, name, "#{config.site_url}#{path}/")
                   end
        end

        items
      end

      def list_item(position, name, url)
        {
          '@type' => 'ListItem',
          'position' => position,
          'name' => name,
          'item' => url
        }
      end

      def list_item_no_url(position, name)
        {
          '@type' => 'ListItem',
          'position' => position,
          'name' => name
        }
      end

      def humanize(slug)
        slug.gsub(/[-_]/, ' ').gsub(/\b\w/, &:upcase)
      end
    end
  end
end
