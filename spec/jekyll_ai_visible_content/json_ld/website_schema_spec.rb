# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::JsonLd::WebsiteSchema do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
  let(:registry) { JekyllAiVisibleContent::Entity::Registry.new(config) }
  let(:schema) { described_class.new(config, registry) }

  describe '#build' do
    subject(:result) { schema.build }

    it 'sets @type to WebSite' do
      expect(result['@type']).to eq('WebSite')
    end

    it 'sets @id' do
      expect(result['@id']).to eq('https://example.com/#website')
    end

    it 'sets url' do
      expect(result['url']).to eq('https://example.com')
    end

    it 'includes publisher reference' do
      expect(result['publisher']['@id']).to eq('https://example.com/#eugene-leontev')
    end

    it 'includes SearchAction' do
      action = result['potentialAction']
      expect(action['@type']).to eq('SearchAction')
      expect(action['target']).to include('search?q=')
    end
  end
end
