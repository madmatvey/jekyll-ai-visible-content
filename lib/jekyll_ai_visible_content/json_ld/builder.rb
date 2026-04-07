# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class Builder
      attr_reader :config, :registry

      def initialize(config, registry)
        @config = config
        @registry = registry
      end

      def build_for_page(page)
        nodes = []
        page_data = page.data

        if person_page?(page)
          nodes << PersonSchema.new(config, registry).build
          nodes << WebsiteSchema.new(config, registry).build if config.json_ld['include_website_schema']
        elsif post_page?(page) && config.json_ld['include_blog_posting']
          nodes << BlogPostingSchema.new(config, registry, page).build
        end

        if config.json_ld['include_breadcrumbs']
          crumbs = BreadcrumbSchema.new(config, page).build
          nodes << crumbs if crumbs
        end

        nodes << FaqSchema.new(config, page).build if config.json_ld['include_faq'] && page_data['faq']&.any?

        nodes << HowToSchema.new(config, page).build if config.json_ld['include_how_to'] && page_data['how_to']

        nodes.compact
      end

      def build_for_homepage
        nodes = []
        nodes << PersonSchema.new(config, registry).build if registry.primary_entity
        nodes << WebsiteSchema.new(config, registry).build if config.json_ld['include_website_schema']
        nodes.compact
      end

      def to_script_tag(nodes, compact: nil)
        return '' if nodes.empty?

        use_compact = compact.nil? ? config.json_ld['compact'] : compact
        graph = { '@context' => 'https://schema.org', '@graph' => nodes }
        json = use_compact ? JSON.generate(graph) : JSON.pretty_generate(graph)
        %(<script type="application/ld+json">\n#{json}\n</script>)
      end

      private

      def person_page?(page)
        page.data['entity_type'] == 'Person' ||
          (page.respond_to?(:url) && page.url&.match?(%r{/about/?$}))
      end

      def post_page?(page)
        page.respond_to?(:collection) && page.collection&.label == 'posts'
      end
    end
  end
end
