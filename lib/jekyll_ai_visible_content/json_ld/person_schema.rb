# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class PersonSchema
      attr_reader :config, :registry

      def initialize(config, registry)
        @config = config
        @registry = registry
      end

      def build
        registry.primary_entity_hash
      end
    end
  end
end
