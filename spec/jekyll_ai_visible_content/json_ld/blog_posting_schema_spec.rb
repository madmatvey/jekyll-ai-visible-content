# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::JsonLd::BlogPostingSchema do
  let(:site) do
    s = make_site
    s.process
    s
  end
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
  let(:registry) { JekyllAiVisibleContent::Entity::Registry.new(config) }
  let(:post) { site.posts.docs.find { |p| p.url.include?('postgresql') } }
  let(:schema) { described_class.new(config, registry, post) }

  describe '#build' do
    subject(:result) { schema.build }

    it 'sets @type to BlogPosting' do
      expect(result['@type']).to eq('BlogPosting')
    end

    it 'sets headline from title' do
      expect(result['headline']).to eq('Optimizing PostgreSQL Queries: From 2 Seconds to 20ms')
    end

    it 'links author via @id' do
      expect(result['author']['@id']).to eq('https://example.com/#eugene-leontev')
    end

    it 'includes datePublished' do
      expect(result['datePublished']).to be_a(String)
      expect(result['datePublished']).to include('2025-01-15')
    end

    it 'includes keywords from tags' do
      expect(result['keywords']).to include('postgresql')
    end

    it 'includes about from topics' do
      names = result['about'].map { |a| a['name'] }
      expect(names).to include('PostgreSQL')
    end

    it 'includes mainEntityOfPage' do
      expect(result['mainEntityOfPage']['@type']).to eq('WebPage')
    end

    it 'includes isPartOf website reference' do
      expect(result['isPartOf']['@id']).to eq('https://example.com/#website')
    end
  end
end
