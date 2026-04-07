# frozen_string_literal: true

module JekyllAiVisibleContent
  module Tags
    class AiBreadcrumbTag < Liquid::Tag
      def render(context)
        site = context.registers[:site]
        page = context.registers[:page]
        config = JekyllAiVisibleContent.config(site)
        return "" unless config.enabled? && config.json_ld["include_breadcrumbs"]

        url = page["url"] || "/"
        segments = url.to_s.split("/").reject(&:empty?)
        return "" if segments.empty?

        items = [breadcrumb_item("Home", "#{config.site_url}/")]

        path = ""
        segments.each_with_index do |segment, idx|
          path = "#{path}/#{segment}"
          name = if idx == segments.size - 1
                   page["title"] || humanize(segment)
                 else
                   humanize(segment)
                 end

          if idx == segments.size - 1
            items << %(<li><span aria-current="page">#{name}</span></li>)
          else
            items << breadcrumb_item(name, "#{config.site_url}#{path}/")
          end
        end

        %(<nav aria-label="Breadcrumb"><ol>#{items.join}</ol></nav>)
      end

      private

      def breadcrumb_item(name, url)
        %(<li><a href="#{url}">#{name}</a></li>)
      end

      def humanize(slug)
        slug.gsub(/[-_]/, " ").gsub(/\b\w/, &:upcase)
      end
    end
  end
end

Liquid::Template.register_tag("ai_breadcrumbs", JekyllAiVisibleContent::Tags::AiBreadcrumbTag)
