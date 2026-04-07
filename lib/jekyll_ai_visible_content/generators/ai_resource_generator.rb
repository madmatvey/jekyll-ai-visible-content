# frozen_string_literal: true

require 'json'
require 'yaml'

module JekyllAiVisibleContent
  module Generators
    class AiResourceGenerator < Jekyll::Generator
      safe true
      priority :low

      def generate(site)
        config = JekyllAiVisibleContent.config(site)
        return unless config.enabled?
        return unless config.ai_resources['enabled']

        formats = config.ai_resources['formats'] || %w[json yaml markdown]
        base_path = config.ai_resources['base_path'] || '/ai'

        entity_index = build_entity_index(site, config)
        page_resources = {}

        entity_index.each_value do |entry|
          paths = generate_resource_files(site, config, entry, formats, base_path)
          entry[:pages].each do |page_url|
            page_resources[page_url] ||= []
            page_resources[page_url].concat(paths)
          end
        end

        page_resources.each_value(&:uniq!)

        site.data['ai_page_resources'] = page_resources
        site.data['ai_entity_resources'] = entity_index.transform_values { |e| e[:paths] }
      end

      private

      def build_entity_index(site, config)
        index = {}
        docs = ContentFilter.content_pages(site, config)

        docs.each do |doc|
          entities = EntityClassifier.classify_page(doc, config)
          entities.each do |entity|
            key = "#{entity[:type]}/#{entity[:slug]}"
            index[key] ||= { type: entity[:type], slug: entity[:slug], name: entity[:name], pages: [], paths: [] }
            index[key][:pages] << doc.url unless index[key][:pages].include?(doc.url)
          end
        end

        index
      end

      def generate_resource_files(site, config, entry, formats, base_path)
        paths = []
        dir = "#{base_path}/#{entry[:type]}"

        formats.each do |fmt|
          ext = format_extension(fmt)
          filename = "#{entry[:slug]}#{ext}"
          content = build_content(config, entry, fmt)

          path = "#{dir}/#{filename}"

          page = Jekyll::PageWithoutAFile.new(site, site.source, dir.sub(%r{^/}, ''), filename)
          page.content = content
          page.data['layout'] = nil
          page.data['sitemap'] = false
          page.data['permalink'] = path
          site.pages << page

          paths << path
        end

        entry[:paths] = paths
        paths
      end

      def build_content(config, entry, format)
        case format
        when 'json' then build_json(config, entry)
        when 'yaml' then build_yaml(config, entry)
        when 'markdown' then build_markdown(config, entry)
        end
      end

      def build_json(config, entry)
        data = resource_data(config, entry)
        JSON.pretty_generate(data)
      end

      def build_yaml(config, entry)
        data = resource_data(config, entry)
        YAML.dump(data)
      end

      def build_markdown(config, entry)
        data = resource_data(config, entry)
        lines = []
        lines << "# #{data['name']}"
        lines << ''
        lines << "- **Type**: #{data['@type']}"
        lines << "- **Category**: #{entry[:type]}"
        lines << ''

        if data['description']
          lines << data['description']
          lines << ''
        end

        if data['jobTitle']
          lines << "- **Role**: #{data['jobTitle']}"
          lines << ''
        end

        if data['sameAs']&.any?
          lines << '## Links'
          lines << ''
          data['sameAs'].each { |url| lines << "- <#{url}>" }
          lines << ''
        end

        if data['mentions_on']&.any?
          lines << '## Pages'
          lines << ''
          data['mentions_on'].each do |mention|
            lines << "- [#{mention['title'] || mention['url']}](#{mention['url']})"
          end
          lines << ''
        end

        lines.join("\n")
      end

      def resource_data(config, entry)
        data = {
          '@context' => 'https://schema.org',
          '@type' => schema_type(entry[:type]),
          'name' => entry[:name],
          'mentions_on' => entry[:pages].map { |url| { 'url' => url } }
        }

        enrich_person_data(data, config) if entry[:type] == 'person'
        data
      end

      def enrich_person_data(data, config)
        entity = config.entity
        data['@type'] = 'Person'
        data['description'] = entity['description']&.strip if entity['description']
        data['jobTitle'] = entity['job_title'] if entity['job_title']
        data['email'] = entity['email'] if entity['email']
        data['image'] = entity['image'] if entity['image']
        data['sameAs'] = entity['same_as'] if entity['same_as']&.any?

        loc = entity['location']
        return unless loc&.values&.any?

        data['address'] = {
          '@type' => 'PostalAddress',
          'addressLocality' => loc['locality'],
          'addressCountry' => loc['country']
        }.compact
      end

      def schema_type(entity_type)
        case entity_type
        when 'person' then 'Person'
        when 'entity' then 'Organization'
        else 'Thing'
        end
      end

      def format_extension(format)
        case format
        when 'json' then '.json'
        when 'yaml' then '.yml'
        when 'markdown' then '.md'
        else ".#{format}"
        end
      end
    end
  end
end
