# frozen_string_literal: true

module JekyllAiVisibleContent
  module Validators
    class JsonLdValidator
      REQUIRED_PERSON_FIELDS = %w[@type @id name].freeze
      REQUIRED_POSTING_FIELDS = %w[@type headline author].freeze

      attr_reader :config

      def initialize(config)
        @config = config
      end

      def validate
        errors = []
        errors.concat(validate_entity_config)
        errors
      end

      def validate_node(node)
        errors = []
        return errors unless node.is_a?(Hash)

        case node["@type"]
        when "Person"
          errors.concat(validate_fields(node, REQUIRED_PERSON_FIELDS, "Person"))
        when "BlogPosting"
          errors.concat(validate_fields(node, REQUIRED_POSTING_FIELDS, "BlogPosting"))
        end

        errors
      end

      private

      def validate_entity_config
        errors = []
        entity = config.entity

        unless entity["name"] && !entity["name"].strip.empty?
          errors << "Entity name is required in ai_visible_content.entity.name"
        end

        if entity["id_slug"].nil? && entity["name"].nil?
          errors << "Entity requires either id_slug or name to generate @id"
        end

        errors
      end

      def validate_fields(node, required, type_name)
        missing = required.select { |f| node[f].nil? || node[f].to_s.strip.empty? }
        missing.map { |f| "#{type_name} JSON-LD missing required field: #{f}" }
      end
    end
  end
end
