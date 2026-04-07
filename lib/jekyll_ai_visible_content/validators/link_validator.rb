# frozen_string_literal: true

module JekyllAiVisibleContent
  module Validators
    class LinkValidator
      attr_reader :config, :site

      def initialize(config, site)
        @config = config
        @site = site
      end

      def validate
        warnings = []
        warnings.concat(check_orphan_pages) if config.validation["warn_orphan_pages"]
        warnings
      end

      private

      def check_orphan_pages
        orphans = site.data["ai_orphan_pages"] || []
        orphans.map { |url| "Orphan page (no inbound links): #{url}" }
      end
    end
  end
end
