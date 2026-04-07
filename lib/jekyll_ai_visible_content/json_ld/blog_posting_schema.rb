# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class BlogPostingSchema
      attr_reader :config, :registry, :page

      def initialize(config, registry, page)
        @config = config
        @registry = registry
        @page = page
      end

      def build
        data = page.data
        url = absolute_url(page.url)

        posting = {
          "@type" => "BlogPosting",
          "@id" => "#{url}#article",
          "mainEntityOfPage" => {
            "@type" => "WebPage",
            "@id" => url
          },
          "headline" => data["title"],
          "description" => data["description"]&.to_s&.strip,
          "datePublished" => format_date(data["date"]),
          "dateModified" => format_date(data["last_modified_at"] || data["date"]),
          "author" => registry.primary_entity_ref,
          "publisher" => registry.primary_entity_ref,
          "isPartOf" => { "@id" => "#{config.site_url}/#website" }
        }

        append_image(posting, data)
        append_keywords(posting, data)
        append_about(posting, data)
        append_word_count(posting)
        append_article_body(posting)

        posting.compact
      end

      private

      def append_image(posting, data)
        return unless data["image"]

        posting["image"] = absolute_url(data["image"])
      end

      def append_keywords(posting, data)
        tags = data["tags"] || data["keywords"]
        posting["keywords"] = tags if tags&.any?
      end

      def append_about(posting, data)
        topics = data["topics"] || data["categories"]
        return unless topics&.any?

        posting["about"] = topics.map { |t| { "@type" => "Thing", "name" => t } }
      end

      def append_word_count(posting)
        content = page.content
        return unless content

        posting["wordCount"] = content.split(/\s+/).size
      end

      def append_article_body(posting)
        mode = config.json_ld["article_body"]
        case mode
        when "full"
          posting["articleBody"] = strip_html(page.content) if page.content
        when "excerpt"
          excerpt_text = page.data["description"] || page.data["excerpt"]&.to_s
          posting["articleBody"] = strip_html(excerpt_text.to_s).strip if excerpt_text
        end
      end

      def format_date(date)
        return nil unless date

        if date.respond_to?(:iso8601)
          date.iso8601
        elsif date.respond_to?(:strftime)
          date.strftime("%Y-%m-%dT%H:%M:%S%:z")
        else
          date.to_s
        end
      end

      def absolute_url(path)
        return path if path&.start_with?("http")

        "#{config.site_url}#{path}"
      end

      def strip_html(text)
        text.to_s.gsub(/<[^>]+>/, "").gsub(/\s+/, " ").strip
      end
    end
  end
end
