# frozen_string_literal: true

module JekyllAiVisibleContent
  module ContentFilter
    GENERATED_NAMES = %w[
      robots.txt llms.txt llms-full.txt entity-map.json
      sitemap.xml feed.xml atom.xml redirects.json
    ].freeze

    ASSET_EXTENSIONS = %w[
      .js .css .scss .map .json .xml .txt .webmanifest .ico .svg .png .jpg .jpeg .gif .woff .woff2 .ttf .eot
    ].freeze

    UTILITY_PATH_PATTERNS = [
      %r{^/404\.html$},
      %r{^/tags/},
      %r{^/categories/},
      %r{^/assets/},
      %r{^/page\d+/},
      %r{^/norobots/}
    ].freeze

    class << self
      def content_page?(doc, config = nil)
        return false unless html_output?(doc)
        return false if generated_file?(doc)
        return false if asset_path?(doc)
        return false if redirect_page?(doc)
        return false if utility_page?(doc)
        return false if excluded_path?(doc, config)

        true
      end

      def content_pages(site, config = nil)
        site.posts.docs + site.pages.select { |p| content_page?(p, config) }
      end

      private

      def html_output?(doc)
        ext = doc.respond_to?(:output_ext) ? doc.output_ext : nil
        ext ||= File.extname(doc.respond_to?(:name) ? doc.name.to_s : doc.url.to_s)
        return true if ['.html', '.htm', '.md', '.markdown'].include?(ext)

        url = doc.respond_to?(:url) ? doc.url.to_s : ''
        url.end_with?('/') && !url.match?(/\.\w+$/)
      end

      def generated_file?(doc)
        name = doc.respond_to?(:name) ? doc.name : File.basename(doc.url.to_s)
        GENERATED_NAMES.include?(name)
      end

      def asset_path?(doc)
        url = doc.respond_to?(:url) ? doc.url.to_s : ''
        return true if url.start_with?('/assets/')

        ext = File.extname(url)
        ASSET_EXTENSIONS.include?(ext)
      end

      def redirect_page?(doc)
        return true if doc.respond_to?(:data) && doc.data['redirect_to']

        name = doc.respond_to?(:name) ? doc.name : File.basename(doc.url.to_s)
        name == 'redirect.html'
      end

      def utility_page?(doc)
        url = doc.respond_to?(:url) ? doc.url.to_s : ''
        UTILITY_PATH_PATTERNS.any? { |pattern| url.match?(pattern) }
      end

      def excluded_path?(doc, config)
        return false unless config

        exclude_paths = config.validation['exclude_paths']
        return false unless exclude_paths&.any?

        url = doc.respond_to?(:url) ? doc.url.to_s : ''
        path = doc.respond_to?(:relative_path) ? doc.relative_path.to_s : url

        exclude_paths.any? do |pattern|
          File.fnmatch?(pattern, url) || File.fnmatch?(pattern, path)
        end
      end
    end
  end
end
