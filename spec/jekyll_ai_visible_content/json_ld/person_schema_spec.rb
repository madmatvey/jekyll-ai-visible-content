# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::JsonLd::PersonSchema do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
  let(:registry) { JekyllAiVisibleContent::Entity::Registry.new(config) }
  let(:schema) { described_class.new(config, registry) }

  describe '#build' do
    subject(:result) { schema.build }

    it 'returns Person entity hash' do
      expect(result['@type']).to eq('Person')
      expect(result['@id']).to eq('https://example.com/#eugene-leontev')
      expect(result['name']).to eq('Eugene Leontev')
    end

    it 'delegates to registry primary entity' do
      expect(result).to eq(registry.primary_entity_hash)
    end
  end
end
