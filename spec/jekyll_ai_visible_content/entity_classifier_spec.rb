# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::EntityClassifier do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent.config(site) }

  describe '.slugify' do
    it 'converts name to lowercase slug' do
      expect(described_class.slugify('Ruby on Rails')).to eq('ruby-on-rails')
    end

    it 'strips leading and trailing hyphens' do
      expect(described_class.slugify('--test--')).to eq('test')
    end

    it 'replaces non-alphanumeric characters' do
      expect(described_class.slugify('C++ & Rust')).to eq('c-rust')
    end
  end

  describe '.classify_page' do
    context 'with a person/about page' do
      let(:page) do
        p = make_page(site,
                      title: 'Eugene Leontev — Senior Backend Engineer',
                      description: 'About Eugene Leontev',
                      entity_type: 'Person')
        p.instance_variable_set(:@url, '/about/')
        p
      end

      it 'includes the primary entity as person type' do
        results = described_class.classify_page(page, config)
        person = results.find { |e| e[:type] == 'person' }
        expect(person).not_to be_nil
        expect(person[:slug]).to eq('eugene-leontev')
        expect(person[:name]).to eq('Eugene Leontev')
      end

      it 'ranks primary entity highest' do
        results = described_class.classify_page(page, config)
        expect(results.first[:type]).to eq('person')
      end
    end

    context 'with a post mentioning topics' do
      let(:post) do
        p = make_page(site,
                      title: 'Optimizing PostgreSQL Queries',
                      description: 'A deep dive into PostgreSQL',
                      topics: ['PostgreSQL', 'Query Optimization'])
        p.instance_variable_set(:@content, 'We used Ruby on Rails and AWS.')
        p
      end

      it 'includes front matter topics' do
        results = described_class.classify_page(post, config)
        slugs = results.map { |e| e[:slug] }
        expect(slugs).to include('postgresql', 'query-optimization')
      end

      it 'detects knows_about topics from body' do
        results = described_class.classify_page(post, config)
        slugs = results.map { |e| e[:slug] }
        expect(slugs).to include('ruby-on-rails', 'aws')
      end

      it 'ranks front matter topics above body detections' do
        results = described_class.classify_page(post, config)
        fm_topic = results.find { |e| e[:slug] == 'postgresql' }
        body_topic = results.find { |e| e[:slug] == 'aws' }
        expect(fm_topic[:relevance]).to be > body_topic[:relevance]
      end
    end

    context 'with max_links_per_page limit' do
      let(:post) do
        p = make_page(site,
                      title: 'PostgreSQL',
                      description: 'PostgreSQL',
                      topics: %w[PostgreSQL AWS Ruby])
        p.instance_variable_set(:@content, 'Ruby on Rails and AWS and PostgreSQL')
        p
      end

      it 'caps results at max_links_per_page' do
        limited_site = make_site('ai_visible_content' => { 'ai_resources' => { 'max_links_per_page' => 2 } })
        limited_config = JekyllAiVisibleContent.config(limited_site)
        results = described_class.classify_page(post, limited_config)
        expect(results.size).to be <= 2
      end
    end

    context 'with a page having no entities' do
      let(:page) do
        p = make_page(site, title: 'Privacy Policy', description: 'Legal information')
        p.instance_variable_set(:@url, '/terms/privacy-policy/')
        p.instance_variable_set(:@content, 'This is our privacy policy.')
        p
      end

      it 'falls back to a general topic entity derived from URL' do
        results = described_class.classify_page(page, config)
        expect(results).not_to be_empty
        expect(results.first[:type]).to eq('topic')
        expect(results.first[:slug]).to eq('privacy-policy')
      end
    end

    context 'deduplication' do
      let(:post) do
        p = make_page(site,
                      title: 'PostgreSQL tips',
                      description: 'PostgreSQL optimization',
                      topics: ['PostgreSQL'])
        p.instance_variable_set(:@content, 'PostgreSQL is great')
        p
      end

      it 'deduplicates entities by slug' do
        results = described_class.classify_page(post, config)
        pg_entries = results.select { |e| e[:slug] == 'postgresql' }
        expect(pg_entries.size).to eq(1)
      end
    end
  end
end
