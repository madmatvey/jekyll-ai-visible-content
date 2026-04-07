# frozen_string_literal: true

module JekyllAiVisibleContent
  module Generators
    class RobotsTxtGenerator < Jekyll::Generator
      safe true
      priority :low

      CRAWLER_MAP = {
        "allow_gptbot" => "GPTBot",
        "allow_perplexitybot" => "PerplexityBot",
        "allow_claudebot" => "ClaudeBot",
        "allow_googlebot" => "Googlebot",
        "allow_bingbot" => "Bingbot"
      }.freeze

      def generate(site)
        config = JekyllAiVisibleContent.config(site)
        return unless config.enabled? && config.crawlers["generate_robots_txt"]

        content = render_robots_txt(config)
        page = Jekyll::PageWithoutAFile.new(site, site.source, "", "robots.txt")
        page.content = content
        page.data["layout"] = nil
        page.data["sitemap"] = false
        site.pages << page
      end

      private

      def render_robots_txt(config)
        lines = []
        lines << "User-agent: *"
        lines << "Allow: /"
        lines << ""

        CRAWLER_MAP.each do |key, agent|
          next unless config.crawlers[key]

          lines << "User-agent: #{agent}"
          lines << "Allow: /"
          lines << ""
        end

        (config.crawlers["custom_rules"] || []).each do |rule|
          lines << "User-agent: #{rule['user_agent']}"
          lines << "#{rule['directive']}: #{rule['path']}" if rule["directive"] && rule["path"]
          lines << ""
        end

        lines << "Sitemap: #{config.site_url}/sitemap.xml"
        lines << ""
        lines.join("\n")
      end
    end
  end
end
