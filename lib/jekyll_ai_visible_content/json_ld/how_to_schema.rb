# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class HowToSchema
      attr_reader :config, :page

      def initialize(config, page)
        @config = config
        @page = page
      end

      def build
        how_to = page.data["how_to"]
        return nil unless how_to

        data = {
          "@type" => "HowTo",
          "name" => how_to["name"]
        }

        data["totalTime"] = how_to["total_time"] if how_to["total_time"]
        data["step"] = build_steps(how_to["steps"]) if how_to["steps"]&.any?

        data.compact
      end

      private

      def build_steps(steps)
        steps.each_with_index.map do |step, idx|
          {
            "@type" => "HowToStep",
            "position" => idx + 1,
            "name" => step["name"],
            "text" => step["text"]
          }.compact
        end
      end
    end
  end
end
