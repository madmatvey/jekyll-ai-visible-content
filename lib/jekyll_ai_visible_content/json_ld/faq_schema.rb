# frozen_string_literal: true

module JekyllAiVisibleContent
  module JsonLd
    class FaqSchema
      attr_reader :config, :page

      def initialize(config, page)
        @config = config
        @page = page
      end

      def build
        faq_items = page.data['faq']
        return nil unless faq_items&.any?

        {
          '@type' => 'FAQPage',
          'mainEntity' => faq_items.map { |item| build_question(item) }
        }
      end

      private

      def build_question(item)
        {
          '@type' => 'Question',
          'name' => item['question'],
          'acceptedAnswer' => {
            '@type' => 'Answer',
            'text' => item['answer']
          }
        }
      end
    end
  end
end
