# frozen_string_literal: true

module JekyllAiVisibleContent
  module Tags
    class AiJsonLdTag < Liquid::Tag
      def render(context)
        site = context.registers[:site]
        page = context.registers[:page]
        config = JekyllAiVisibleContent.config(site)
        return "" unless config.enabled?

        registry = Entity::Registry.new(config)
        builder = JsonLd::Builder.new(config, registry)

        page_obj = find_page_object(site, page)
        return "" unless page_obj

        nodes = if homepage?(page)
                  builder.build_for_homepage
                else
                  builder.build_for_page(page_obj)
                end

        return "" if nodes.empty?

        skip_types = seo_tag_types(config)
        nodes.reject! { |n| skip_types.include?(n["@type"]) } if skip_types.any?

        builder.to_script_tag(nodes)
      end

      private

      def homepage?(page)
        url = page["url"] || page["permalink"]
        url == "/" || url == "/index.html"
      end

      def find_page_object(site, page_hash)
        url = page_hash["url"] || page_hash["permalink"]
        site.posts.docs.find { |p| p.url == url } ||
          site.pages.find { |p| p.url == url }
      end

      def seo_tag_types(config)
        return [] unless config.seo_tag_present?

        %w[WebSite]
      end
    end
  end
end

Liquid::Template.register_tag("ai_json_ld", JekyllAiVisibleContent::Tags::AiJsonLdTag)
