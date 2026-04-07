# frozen_string_literal: true

module JekyllAiVisibleContent
  module Tags
    class AiRelatedPostsTag < Liquid::Tag
      LIMIT_SYNTAX = /limit\s*:\s*(\d+)/

      def initialize(tag_name, markup, tokens)
        super
        match = markup.match(LIMIT_SYNTAX)
        @limit = match ? match[1].to_i : nil
      end

      def render(context)
        site = context.registers[:site]
        page = context.registers[:page]
        config = JekyllAiVisibleContent.config(site)
        return "" unless config.enabled? && config.linking["enable_related_posts"]

        limit = @limit || config.linking["related_posts_limit"] || 3
        page_obj = find_page_object(site, page)
        return "" unless page_obj

        related = find_related(site, page_obj, limit)
        return "" if related.empty?

        render_html(related)
      end

      private

      def find_page_object(site, page_hash)
        url = page_hash["url"]
        site.posts.docs.find { |p| p.url == url } || site.pages.find { |p| p.url == url }
      end

      def find_related(site, current, limit)
        explicit = current.data["related_slugs"]
        if explicit&.any?
          posts = explicit.filter_map do |slug|
            site.posts.docs.find { |p| p.data["slug"] == slug || p.url.include?(slug) }
          end
          return posts.first(limit) if posts.any?
        end

        scored = site.posts.docs.reject { |p| p.url == current.url }.map do |post|
          score = jaccard_similarity(current.data["tags"] || [], post.data["tags"] || []) * 3
          score += jaccard_similarity(current.data["categories"] || [], post.data["categories"] || []) * 2
          score += jaccard_similarity(current.data["topics"] || [], post.data["topics"] || [])
          [post, score]
        end

        scored.select { |_, s| s > 0 }.sort_by { |_, s| -s }.first(limit).map(&:first)
      end

      def jaccard_similarity(set_a, set_b)
        a = set_a.map(&:to_s).map(&:downcase)
        b = set_b.map(&:to_s).map(&:downcase)
        intersection = (a & b).size.to_f
        union = (a | b).size.to_f
        union.zero? ? 0.0 : intersection / union
      end

      def render_html(posts)
        lines = []
        lines << '<nav aria-label="Related posts">'
        lines << "  <h2>Related Posts</h2>"
        lines << "  <ul>"

        posts.each do |post|
          lines << '    <li itemscope itemtype="https://schema.org/BlogPosting">'
          lines << "      <a itemprop=\"url\" href=\"#{post.url}\">"
          lines << "        <span itemprop=\"headline\">#{post.data['title']}</span>"
          lines << "      </a>"
          if post.data["date"]
            dt = post.data["date"].strftime("%Y-%m-%d")
            lines << "      <time itemprop=\"datePublished\" datetime=\"#{dt}\">#{post.data['date'].strftime('%b %d, %Y')}</time>"
          end
          lines << "    </li>"
        end

        lines << "  </ul>"
        lines << "</nav>"
        lines.join("\n")
      end
    end
  end
end

Liquid::Template.register_tag("ai_related_posts", JekyllAiVisibleContent::Tags::AiRelatedPostsTag)
