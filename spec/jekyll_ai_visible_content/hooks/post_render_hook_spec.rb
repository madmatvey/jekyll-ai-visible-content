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

    it 'does not link entities inside HTML attributes' do
      html_with_image = <<~HTML
        <html>
        <body>
          <img alt="Redis is single-threaded on the outside, but multithreaded on the inside" src="/hero.jpg">
          <p>Redis is fast.</p>
        </body>
        </html>
      HTML

      result = described_class.send(
        :link_entities,
        html_with_image,
        definitions: definitions,
        max_per: 1,
        context: :body
      )

      expect(result).to include('alt="Redis is single-threaded on the outside, but multithreaded on the inside"')
      expect(result).not_to include('alt="<a ')
      expect(result).to include('<p><a href="/topics/redis/"')
    end

    it 'does not link entities inside configured skipped tags by default' do
      html_with_code = <<~HTML
        <html>
        <body>
          <p>Redis is fast.</p>
          <pre><code>Redis CLI examples should stay plain.</code></pre>
          <kbd>Redis</kbd>
          <samp>Redis response</samp>
        </body>
        </html>
      HTML

      result = described_class.send(
        :link_entities,
        html_with_code,
        definitions: definitions,
        max_per: 10,
        context: :body
      )

      expect(result).to include('<p><a href="/topics/redis/"')
      expect(result).to include('<pre><code>Redis CLI examples should stay plain.</code></pre>')
      expect(result).to include('<kbd>Redis</kbd>')
      expect(result).to include('<samp>Redis response</samp>')
    end

    it 'allows skipped tags to be customized' do
      html_with_code = <<~HTML
        <html>
        <body>
          <code>Redis can be linked when code is not skipped.</code>
        </body>
        </html>
      HTML

      result = described_class.send(
        :link_entities,
        html_with_code,
        definitions: definitions,
        max_per: 1,
        context: :body,
        skip_tags: %w[a script style template]
      )

      expect(result).to include('<code><a href="/topics/redis/"')
    end

    it 'sanitizes metadata context to plain text' do
      metadata = '<span> Redis </span>   <em>performance</em>'

      result = described_class.send(:link_entities, metadata, definitions: definitions, max_per: 1, context: :metadata)

      expect(result).to eq('Redis performance')
      expect(result).not_to include('<')
    end

    it 'allows pages and posts by default' do
      site = make_site
      config = JekyllAiVisibleContent.config(site)
      page = make_page(site)
      post = make_post(site, '2025-01-15-optimizing-postgresql-queries.md')

      expect(described_class.send(:auto_linkable_content?, page, config)).to be true
      expect(described_class.send(:auto_linkable_content?, post, config)).to be true
    end

    it 'can limit auto-linking to posts only' do
      site = make_site('ai_visible_content' => {
                         'linking' => { 'auto_link_content_types' => ['posts'] }
                       })
      config = JekyllAiVisibleContent.config(site)
      page = make_page(site)
      post = make_post(site, '2025-01-15-optimizing-postgresql-queries.md')

      expect(described_class.send(:auto_linkable_content?, page, config)).to be false
      expect(described_class.send(:auto_linkable_content?, post, config)).to be true
    end
  end
end
