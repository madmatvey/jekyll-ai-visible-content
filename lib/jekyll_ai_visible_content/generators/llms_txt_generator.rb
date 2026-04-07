# frozen_string_literal: true

module JekyllAiVisibleContent
  module Generators
    class LlmsTxtGenerator < Jekyll::Generator
      safe true
      priority :low

      def generate(site)
        config = JekyllAiVisibleContent.config(site)
        return unless config.enabled? && config.llms_txt['enabled']

        registry = Entity::Registry.new(config)

        site.pages << build_llms_txt(site, config, registry)
        site.pages << build_llms_full_txt(site, config, registry) if config.llms_txt['include_full_text']
      end

      private

      def build_llms_txt(site, config, registry)
        content = render_llms_txt(config, registry, site, full: false)
        make_page(site, 'llms.txt', content)
      end

      def build_llms_full_txt(site, config, registry)
        content = render_llms_txt(config, registry, site, full: true)
        make_page(site, 'llms-full.txt', content)
      end

      def render_llms_txt(config, registry, site, full:)
        lines = []
        title = config.llms_txt['title'] || config.site_title
        description = config.llms_txt['description'] || config.site_description

        lines << "# #{title}"
        lines << ''
        lines << "> #{description.strip}" if description && !description.strip.empty?
        lines << ''

        append_entity_section(lines, config, registry)
        append_topics_section(lines, config)
        append_custom_sections(lines, config)
        append_posts_section(lines, config, site, full: full)
        append_links_section(lines, config)

        lines.join("\n")
      end

      def append_entity_section(lines, config, _registry)
        entity = config.entity
        return unless entity['name']

        lines << '## About'
        lines << ''
        lines << "#{entity['name']} is #{entity['description']&.strip}" if entity['description']
        lines << ''

        lines << "- Role: #{entity['job_title']}" if entity['job_title']
        loc = entity['location']
        lines << "- Location: #{[loc['locality'], loc['country']].compact.join(', ')}" if loc&.values&.any?
        lines << ''
      end

      def append_topics_section(lines, config)
        topics = config.entity['knows_about']
        return unless topics&.any?

        lines << '## Key Topics'
        lines << ''
        topics.each { |t| lines << "- #{t}" }
        lines << ''
      end

      def append_custom_sections(lines, config)
        sections = config.llms_txt['sections'] || []
        sections.each do |section|
          next unless section['heading']

          lines << "## #{section['heading']}"
          lines << ''
          lines << section['content'].to_s.strip if section['content']
          lines << ''
        end
      end

      def append_posts_section(lines, config, site, full:)
        posts = sorted_posts(site)
        return if posts.empty?

        lines << '## Posts'
        lines << ''

        posts.each do |post|
          url = "#{config.site_url}#{post.url}"
          desc = post.data['description']&.to_s&.strip

          if full
            lines << "### #{post.data['title']}"
            lines << ''
            lines << "URL: #{url}"
            lines << "Date: #{post.data['date']&.strftime('%Y-%m-%d')}" if post.data['date']
            lines << ''
            lines << strip_html_and_liquid(post.content) if post.content
            lines << ''
            lines << '---'
            lines << ''
          else
            entry = "- [#{post.data['title']}](#{url})"
            entry += ": #{desc}" if desc && !desc.empty?
            lines << entry
          end
        end

        lines << ''
      end

      def append_links_section(lines, config)
        lines << '## Links'
        lines << ''
        lines << "- About: #{config.site_url}/about/"

        (config.entity['same_as'] || []).each do |link|
          platform = extract_platform(link)
          lines << "- #{platform}: #{link}"
        end

        lines << ''
      end

      def sorted_posts(site)
        site.posts.docs.sort_by { |p| p.data['date'] || Time.at(0) }.reverse
      end

      def strip_html_and_liquid(text)
        text.to_s
            .gsub(/\{%.*?%\}/m, '')
            .gsub(/\{\{.*?\}\}/m, '')
            .gsub(/<[^>]+>/, '')
            .gsub(/\n{3,}/, "\n\n")
            .strip
      end

      def extract_platform(url)
        case url
        when /linkedin/i then 'LinkedIn'
        when /github/i then 'GitHub'
        when /twitter|x\.com/i then 'Twitter'
        when /mastodon/i then 'Mastodon'
        when /youtube/i then 'YouTube'
        else
          host = URI.parse(url).host
          parts = host&.split('.')
          name = parts && parts.length >= 2 ? parts[-2] : nil
          name&.capitalize || 'Link'
        end
      rescue URI::InvalidURIError
        'Link'
      end

      def make_page(site, name, content)
        page = Jekyll::PageWithoutAFile.new(site, site.source, '', name)
        page.content = content
        page.data['layout'] = nil
        page.data['sitemap'] = false
        page
      end
    end
  end
end
