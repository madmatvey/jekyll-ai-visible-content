# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Configuration do
  let(:site) { make_site }
  let(:config) { described_class.new(site) }

  describe '#enabled?' do
    it 'returns true when enabled in config' do
      expect(config.enabled?).to be true
    end

    it 'returns true by default when key is absent' do
      site = make_site('ai_visible_content' => {})
      cfg = described_class.new(site)
      expect(cfg.enabled?).to be true
    end
  end

  describe '#entity' do
    it 'returns entity hash from config' do
      expect(config.entity['name']).to eq('Eugene Leontev')
      expect(config.entity['type']).to eq('Person')
    end
  end

  describe '#entity_id' do
    it 'builds URI from site url and id_slug' do
      expect(config.entity_id).to eq('https://example.com/#eugene-leontev')
    end

    it 'derives slug from name when id_slug is nil' do
      site = make_site('ai_visible_content' => {
                         'entity' => { 'name' => 'John Doe', 'id_slug' => nil }
                       })
      cfg = described_class.new(site)
      expect(cfg.entity_id).to eq('https://example.com/#john-doe')
    end
  end

  describe '#entity_type' do
    it 'returns configured type' do
      expect(config.entity_type).to eq('Person')
    end
  end

  describe '#json_ld' do
    it 'returns json_ld config with defaults' do
      expect(config.json_ld['auto_inject']).to be true
      expect(config.json_ld['article_body']).to eq('excerpt')
    end
  end

  describe '#linking' do
    it 'defaults to not applying entity links to metadata' do
      expect(config.linking['apply_to_metadata']).to be false
    end
  end

  describe '#site_url' do
    it 'returns site url' do
      expect(config.site_url).to eq('https://example.com')
    end
  end

  describe '#site_title' do
    it 'returns site title' do
      expect(config.site_title).to eq('Test Site')
    end
  end

  describe '#seo_tag_present?' do
    it 'returns false when not present' do
      expect(config.seo_tag_present?).to be false
    end
  end

  describe 'deep merge' do
    it 'merges nested config over defaults' do
      site = make_site('ai_visible_content' => {
                         'json_ld' => { 'compact' => true }
                       })
      cfg = described_class.new(site)
      expect(cfg.json_ld['compact']).to be true
      expect(cfg.json_ld['auto_inject']).to be true
    end
  end
end
