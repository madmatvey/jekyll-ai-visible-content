# frozen_string_literal: true

module JekyllAiVisibleContent
  module Validators
    class EntityConsistencyValidator
      attr_reader :config, :site

      def initialize(config, site)
        @config = config
        @site = site
      end

      def validate
        warnings = []

        warnings.concat(check_name_consistency) if config.validation['warn_name_inconsistency']
        warnings.concat(check_missing_same_as) if config.validation['warn_missing_same_as']
        warnings.concat(check_missing_dates) if config.validation['warn_missing_dates']
        warnings.concat(check_missing_descriptions) if config.validation['warn_missing_descriptions']
        warnings.concat(check_generic_titles)

        warnings
      end

      private

      def check_name_consistency
        warnings = []
        canonical = config.entity['name']
        return warnings unless canonical

        author_config = site.config['author']
        site_author = author_config.is_a?(Hash) ? author_config['name'] : author_config
        if site_author.is_a?(String) && site_author != canonical
          warnings << "Name inconsistency: site.author='#{site_author}' differs from entity.name='#{canonical}'"
        end

        site.posts.docs.each do |post|
          author = post.data['author']
          next unless author.is_a?(String) && author != canonical

          warnings << "Name inconsistency in #{post.relative_path}: author='#{author}' differs from '#{canonical}'"
        end

        warnings
      end

      def check_missing_same_as
        same_as = config.entity['same_as']
        return [] if same_as&.any?

        ['Entity has no sameAs links to external profiles (LinkedIn, GitHub, etc.)']
      end

      def check_missing_dates
        warnings = []
        site.posts.docs.each do |post|
          next if post.data['last_modified_at']

          warnings << "Missing last_modified_at in #{post.relative_path} (freshness scoring disabled)"
        end
        warnings
      end

      def check_missing_descriptions
        warnings = []
        all_docs.each do |doc|
          next if doc.data['description'] && !doc.data['description'].to_s.strip.empty?

          warnings << "Missing description in #{doc.respond_to?(:relative_path) ? doc.relative_path : doc.url}"
        end
        warnings
      end

      def check_generic_titles
        warnings = []
        generic = %w[about blog home page post]

        all_docs.each do |doc|
          title = doc.data['title'].to_s.strip.downcase
          next unless generic.include?(title)

          path = doc.respond_to?(:relative_path) ? doc.relative_path : doc.url
          warnings << "Generic title '#{doc.data['title']}' in #{path} (include entity name for discoverability)"
        end
        warnings
      end

      def all_docs
        site.posts.docs + site.pages
      end
    end
  end
end
