# frozen_string_literal: true

module JekyllAiVisibleContent
  module Tags
    class AiResourceLinksTag < Liquid::Tag
      def render(context)
        site = context.registers[:site]
        page = context.registers[:page]
        config = JekyllAiVisibleContent.config(site)

        return '' unless config.enabled?
        return '' unless config.ai_resources['enabled']

        resources = site.data['ai_page_resources']
        return '' unless resources

        page_url = page['url']
        page_paths = resources[page_url]
        return '' if page_paths.nil? || page_paths.empty?

        lines = page_paths.filter_map do |path|
          ext = File.extname(path)
          rel = Hooks::PostRenderHook::FORMAT_REL_MAP[ext]
          next unless rel

          %(<link rel="#{rel}" href="#{path}">)
        end

        lines << Hooks::PostRenderHook::AI_INSTRUCTION_BLOCK if config.ai_resources['inject_instruction_block']

        lines.join("\n")
      end
    end
  end
end

Liquid::Template.register_tag('ai_resource_links', JekyllAiVisibleContent::Tags::AiResourceLinksTag)
