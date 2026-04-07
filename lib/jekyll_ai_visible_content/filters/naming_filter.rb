# frozen_string_literal: true

module JekyllAiVisibleContent
  module Filters
    module NamingFilter
      def ai_slugify(input)
        input.to_s.strip.downcase
             .gsub(/[^a-z0-9\s-]/, "")
             .gsub(/\s+/, "-")
             .gsub(/-+/, "-")
             .gsub(/(^-|-$)/, "")
      end

      def ai_entity_slug(input)
        ai_slugify(input)
      end

      def ai_canonical_url(input)
        url = input.to_s.strip
        url = "#{url}/" unless url.end_with?("/") || url.match?(/\.\w+$/)
        url
      end
    end
  end
end

Liquid::Template.register_filter(JekyllAiVisibleContent::Filters::NamingFilter)
