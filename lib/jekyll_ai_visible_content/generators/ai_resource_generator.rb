# frozen_string_literal: true

require 'json'
require 'yaml'
require 'date'

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
        structured_formats = formats - ['markdown']
        base_path = config.ai_resources['base_path'] || '/ai'
        docs = ContentFilter.content_pages(site, config)

        entity_index = build_entity_index(docs, config)
        page_resources = {}

        entity_index.each_value do |entry|
          paths = generate_resource_files(site, config, entry, structured_formats, base_path)
          entry[:pages].each do |page_url|
            page_resources[page_url] ||= []
            page_resources[page_url].concat(paths)
          end
        end

        if formats.include?('markdown')
          docs.each do |doc|
            page_resources[doc.url] ||= []
            page_resources[doc.url] << generate_page_markdown_resource(site, doc, base_path)
          end
        end

        page_resources.each_value(&:uniq!)

        site.data['ai_page_resources'] = page_resources
        site.data['ai_entity_resources'] = entity_index.transform_values { |e| e[:paths] }
      end

      private

      def build_entity_index(docs, config)
        index = {}

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
        return paths if formats.empty?

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

      def generate_page_markdown_resource(site, doc, base_path)
        slug = page_slug(doc)
        dir = "#{base_path}/page"
        filename = "#{slug}.md"
        path = "#{dir}/#{filename}"
        content = build_page_markdown_content(doc)

        page = Jekyll::PageWithoutAFile.new(site, site.source, dir.sub(%r{^/}, ''), filename)
        page.content = content
        page.data['layout'] = nil
        page.data['sitemap'] = false
        page.data['permalink'] = path
        site.pages << page
        path
      end

      def build_page_markdown_content(doc)
        front_matter_hash = doc.data.each_with_object({}) do |(key, value), result|
          next if %w[layout sitemap permalink excerpt].include?(key.to_s)

          sanitized = sanitize_front_matter_value(value)
          result[key] = sanitized unless sanitized.nil?
        end
        front_matter = front_matter_hash.to_yaml.sub(/\A---\s*\n/, '').sub(/\n\.\.\.\s*\n?\z/, '')
        source_content = doc.content.to_s

        "---\n#{front_matter}---\n\n#{source_content}"
      end

      def sanitize_front_matter_value(value)
        case value
        when String, Numeric, TrueClass, FalseClass, NilClass
          value
        when Time, Date
          value.iso8601
        when Array
          value.filter_map { |item| sanitize_front_matter_value(item) }
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            sanitized = sanitize_front_matter_value(nested)
            result[key] = sanitized unless sanitized.nil?
          end
        end
      end

      def page_slug(doc)
        from_url = doc.url.to_s.split('/').reject(&:empty?).last
        from_url = from_url.sub(/\.[a-z0-9]+\z/i, '') if from_url
        slug = EntityClassifier.slugify(from_url)
        return slug unless slug.empty?

        from_title = EntityClassifier.slugify(doc.data['title'])
        return from_title unless from_title.empty?

        'home'
      end

      def build_content(config, entry, format)
        case format
        when 'json' then build_json(config, entry)
        when 'yaml' then build_yaml(config, entry)
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
