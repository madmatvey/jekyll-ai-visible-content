# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Hooks::PostRenderHook do
  describe '.link_entities' do
    let(:definitions) do
      {
        'redis' => {
          'name' => 'Redis',
          'url' => '/topics/redis/'
        }
      }
    end

    let(:html) do
      <<~HTML
        <html>
        <head>
          <meta name="description" content="Redis caching strategies">
          <meta property="og:description" content="Redis in production">
          <meta name="twitter:description" content="Redis and queues">
          <script type="application/ld+json">{"description":"Redis for performance"}</script>
        </head>
        <body>
          <p>Redis helps reduce latency.</p>
        </body>
        </html>
      HTML
    end

    it 'links entities only inside body context by default' do
      result = described_class.send(:link_entities, html, definitions: definitions, max_per: 1, context: :body)

      expect(result).to include('<p><a href="/topics/redis/"')
      expect(result).to include('meta name="description" content="Redis caching strategies"')
      expect(result).to include('property="og:description" content="Redis in production"')
      expect(result).to include('name="twitter:description" content="Redis and queues"')
      expect(result).to include('{"description":"Redis for performance"}')
      expect(result).not_to include('<meta name="description" content="<a ')
      expect(result).not_to include('{"description":"<a ')
    end

    it 'sanitizes metadata context to plain text' do
      metadata = '<span> Redis </span>   <em>performance</em>'

      result = described_class.send(:link_entities, metadata, definitions: definitions, max_per: 1, context: :metadata)

      expect(result).to eq('Redis performance')
      expect(result).not_to include('<')
    end
  end
end
