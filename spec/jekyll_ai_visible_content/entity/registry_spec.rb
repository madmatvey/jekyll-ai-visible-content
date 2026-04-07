# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Entity::Registry do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
  let(:registry) { described_class.new(config) }

  describe '#primary_entity' do
    it 'returns a Person entity' do
      expect(registry.primary_entity).to be_a(JekyllAiVisibleContent::Entity::Person)
    end
  end

  describe '#primary_entity_hash' do
    it 'returns hash with @type Person' do
      expect(registry.primary_entity_hash['@type']).to eq('Person')
    end
  end

  describe '#primary_entity_ref' do
    it 'returns a reference with @type and @id' do
      ref = registry.primary_entity_ref
      expect(ref['@type']).to eq('Person')
      expect(ref['@id']).to eq('https://example.com/#eugene-leontev')
    end
  end

  describe '#record_mention and #mention_count' do
    it 'tracks mentions' do
      registry.record_mention('PostgreSQL', '/post-1/')
      registry.record_mention('postgresql', '/post-2/')
      expect(registry.mention_count('PostgreSQL')).to eq(2)
    end
  end

  describe '#pages_for' do
    it 'tracks pages per entity' do
      registry.record_mention('AWS', '/post-1/')
      registry.record_mention('AWS', '/post-2/')
      expect(registry.pages_for('AWS')).to contain_exactly('/post-1/', '/post-2/')
    end

    it 'does not duplicate pages' do
      registry.record_mention('AWS', '/post-1/')
      registry.record_mention('AWS', '/post-1/')
      expect(registry.pages_for('AWS')).to eq(['/post-1/'])
    end
  end

  describe '#entity_definitions' do
    it 'includes definitions from knows_about' do
      defs = registry.entity_definitions
      expect(defs).to have_key('ruby-on-rails')
      expect(defs['ruby-on-rails']['name']).to eq('Ruby on Rails')
    end
  end

  describe '#find_entity_by_name' do
    it 'finds entity by name case-insensitively' do
      result = registry.find_entity_by_name('ruby on rails')
      expect(result['name']).to eq('Ruby on Rails')
    end

    it 'returns nil for unknown entities' do
      expect(registry.find_entity_by_name('Unknown Tech')).to be_nil
    end
  end

  describe '#topic_url' do
    it 'generates topic URL from name' do
      expect(registry.topic_url('Ruby on Rails')).to eq('/topics/ruby-on-rails/')
    end
  end
end
