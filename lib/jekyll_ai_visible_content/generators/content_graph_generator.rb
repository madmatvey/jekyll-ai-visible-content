# frozen_string_literal: true

module JekyllAiVisibleContent
  module Generators
    class ContentGraphGenerator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        config = JekyllAiVisibleContent.config(site)
        return unless config.enabled?

        content_docs = ContentFilter.content_pages(site, config)
        graph = build_link_graph(content_docs, config)
        orphans = find_orphans(graph, content_docs)

        site.data['ai_content_graph'] = graph
        site.data['ai_orphan_pages'] = orphans
      end

      private

      def build_link_graph(docs, config)
        graph = Hash.new { |h, k| h[k] = { 'outbound' => [], 'inbound' => [] } }
        baseurl = normalized_baseurl(config.site.config['baseurl'])

        docs.each do |doc|
          source_url = normalize_url(doc.url, config.site_url, baseurl)
          links = extract_internal_links(doc.output.to_s, config.site_url, baseurl)

          links.each do |target_url|
            graph[source_url]['outbound'] << target_url unless graph[source_url]['outbound'].include?(target_url)
            graph[target_url]['inbound'] << source_url unless graph[target_url]['inbound'].include?(source_url)
          end
        end

        graph
      end

      def find_orphans(graph, docs)
        return [] if docs.empty?

        config = JekyllAiVisibleContent.config(docs.first.site)
        baseurl = normalized_baseurl(config.site.config['baseurl'])
        all_urls = docs.map { |doc| normalize_url(doc.url, config.site_url, baseurl) }
        all_urls.select { |url| (graph[url]['inbound'] || []).empty? && url != '/' }
      end

      def extract_internal_links(content, site_url, baseurl)
        links = []
        content.scan(/href=["']([^"']+)["']/) do |match|
          href = match[0]
          next if href.start_with?('#', 'mailto:', 'tel:', 'javascript:')

          normalized = normalize_url(href, site_url, baseurl)
          links << normalized if normalized
        end
        links.uniq
      end

      def normalize_url(url, site_url, baseurl)
        path = parse_internal_path(url.to_s.strip, site_url)
        return nil unless path

        path = strip_query_and_fragment(path)
        path = strip_baseurl(path, baseurl)
        path = normalize_index(path)
        normalize_slash(path)
      end

      def parse_internal_path(url, site_url)
        return nil if url.empty? || url.start_with?('//')
        return nil if url.match?(/\A(?:mailto|tel|javascript|data):/i)

        if url.start_with?('/')
          url
        elsif site_url && !site_url.empty? && url.start_with?(site_url)
          url.sub(site_url, '')
        end
      end

      def strip_query_and_fragment(path)
        path.split('#').first.split('?').first
      end

      def normalized_baseurl(baseurl)
        return '' unless baseurl && !baseurl.empty?

        value = baseurl.start_with?('/') ? baseurl : "/#{baseurl}"
        value.end_with?('/') ? value[0..-2] : value
      end

      def strip_baseurl(path, baseurl)
        return path if baseurl.empty?
        return '/' if path == baseurl
        return path unless path.start_with?("#{baseurl}/")

        suffix = path.sub(baseurl, '')
        suffix.empty? ? '/' : suffix
      end

      def normalize_index(path)
        return '/' if path == '/index.html'
        return path unless path.end_with?('/index.html')

        "#{path.sub(%r{/index\.html$}, '')}/"
      end

      def normalize_slash(path)
        return '/' if path.empty? || path == '/'
        return path if path.end_with?('/') || path.match?(%r{/\.[^/]+$}) || path.match?(%r{\.[^/]+$})

        "#{path}/"
      end
    end
  end
end
