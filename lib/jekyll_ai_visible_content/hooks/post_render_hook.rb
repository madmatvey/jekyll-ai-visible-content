# frozen_string_literal: true

module JekyllAiVisibleContent
  module Hooks
    module PostRenderHook
      class << self
        def register!
          Jekyll::Hooks.register(:pages, :post_render) { |page| process(page) }
          Jekyll::Hooks.register(:documents, :post_render) { |doc| process(doc) }
        end

        private

        def process(doc)
          return unless doc.output_ext == ".html"
          return unless doc.output

          site = doc.site
          config = JekyllAiVisibleContent.config(site)
          return unless config.enabled?

          inject_json_ld(doc, config) if config.json_ld["auto_inject"]
          auto_link_entities(doc, config) if config.linking["enable_entity_links"]
        end

        def inject_json_ld(doc, config)
          return if doc.output.include?("application/ld+json")

          registry = Entity::Registry.new(config)
          builder = JsonLd::Builder.new(config, registry)

          nodes = builder.build_for_page(doc)
          return if nodes.empty?

          if config.seo_tag_present?
            nodes.reject! { |n| n["@type"] == "WebSite" }
            return if nodes.empty?
          end

          script_tag = builder.to_script_tag(nodes)
          doc.output = doc.output.sub("</head>", "#{script_tag}\n</head>")
        end

        def auto_link_entities(doc, config)
          return unless doc.output

          registry = Entity::Registry.new(config)
          definitions = registry.entity_definitions
          max_per = config.linking["max_links_per_entity_per_post"] || 1

          definitions.each_value do |defn|
            name = defn["name"]
            url = defn["url"]
            next unless name && url

            link_html = %(<a href="#{url}" itemprop="about" itemscope ) +
                        %(itemtype="https://schema.org/Thing"><span itemprop="name">#{name}</span></a>)

            count = 0
            doc.output = doc.output.gsub(%r{(?<=\s|>)#{Regexp.escape(name)}(?=[\s,.<])}i) do |match|
              if count < max_per && !inside_tag?(doc.output, Regexp.last_match.begin(0))
                count += 1
                link_html
              else
                match
              end
            end
          end
        end

        def inside_tag?(html, position)
          preceding = html[0...position]
          last_open = preceding.rindex("<") || -1
          last_close = preceding.rindex(">") || -1
          last_open > last_close
        end
      end
    end
  end
end

JekyllAiVisibleContent::Hooks::PostRenderHook.register!
