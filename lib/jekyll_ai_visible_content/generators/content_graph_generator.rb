# frozen_string_literal: true

module JekyllAiVisibleContent
  module Generators
    class ContentGraphGenerator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        config = JekyllAiVisibleContent.config(site)
        return unless config.enabled?

        graph = build_link_graph(site, config)
        orphans = find_orphans(graph, site)

        site.data['ai_content_graph'] = graph
        site.data['ai_orphan_pages'] = orphans
      end

      private

      def build_link_graph(site, config)
        graph = Hash.new { |h, k| h[k] = { 'outbound' => [], 'inbound' => [] } }

        all_docs(site).each do |doc|
          source_url = doc.url
          links = extract_internal_links(doc.content || '', config.site_url)

          links.each do |target_url|
            graph[source_url]['outbound'] << target_url unless graph[source_url]['outbound'].include?(target_url)
            graph[target_url]['inbound'] << source_url unless graph[target_url]['inbound'].include?(source_url)
          end
        end

        graph
      end

      def find_orphans(graph, site)
        all_urls = all_docs(site).map(&:url)
        all_urls.select { |url| (graph[url]['inbound'] || []).empty? && url != '/' }
      end

      def extract_internal_links(content, site_url)
        links = []
        content.scan(/href=["']([^"']+)["']/) do |match|
          href = match[0]
          next if href.start_with?('#', 'mailto:', 'tel:', 'javascript:')

          if href.start_with?('/')
            links << normalize_url(href)
          elsif href.start_with?(site_url)
            links << normalize_url(href.sub(site_url, ''))
          end
        end
        links.uniq
      end

      def normalize_url(url)
        path = url.split('?').first.split('#').first
        path = "#{path}/" unless path.end_with?('/') || path.match?(/\.\w+$/)
        path
      end

      def all_docs(site)
        site.posts.docs + site.pages
      end
    end
  end
end
