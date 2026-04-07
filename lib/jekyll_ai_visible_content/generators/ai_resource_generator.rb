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
        filename = "#{slug}.txt"
        path = "#{dir}/#{slug}.md"
        content = build_page_markdown_content_from_source(doc)

        page = Jekyll::PageWithoutAFile.new(site, site.source, dir.sub(%r{^/}, ''), filename)
        page.content = content
        page.data['layout'] = nil
        page.data['sitemap'] = false
        page.data['permalink'] = path
        site.pages << page
        path
      end

      def build_page_markdown_content_from_source(doc)
        raw = File.exist?(doc.path) ? File.read(doc.path) : doc.content.to_s
        front_matter, body = extract_front_matter_and_body(raw)
        cleaned_body = strip_liquid_tags(body)

        if front_matter.empty?
          cleaned_body
        else
          "---\n#{front_matter}---\n\n#{cleaned_body}"
        end
      end

      def extract_front_matter_and_body(raw)
        match = raw.match(/\A---\s*\n(.*?)\n---\s*\n?(.*)\z/m)
        return ['', raw] unless match

        ["#{match[1].rstrip}\n", match[2]]
      end

      def strip_liquid_tags(content)
        cleaned = content.to_s
                         .gsub(/\{%\s*comment\s*%\}.*?\{%\s*endcomment\s*%\}/m, '')
                         .gsub(/\{%-?\s*.*?\s*-?%\}/m, '')
                         .gsub(/\{\{\s*.*?\s*\}\}/m, '')
                         .gsub(/\n{3,}/, "\n\n")
                         .strip
        "#{cleaned}\n"
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
