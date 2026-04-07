# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Generators::EntityMapGenerator do
  let(:site) do
    s = make_site
    s.process
    s
  end

  describe 'entity-map.json generation' do
    let(:entity_map_page) { site.pages.find { |p| p.name == 'entity-map.json' } }

    it 'generates entity-map.json' do
      expect(entity_map_page).not_to be_nil
    end

    it 'contains valid JSON' do
      data = JSON.parse(entity_map_page.content)
      expect(data).to have_key('primary_entity')
      expect(data).to have_key('entities')
    end

    it 'includes primary entity info' do
      data = JSON.parse(entity_map_page.content)
      expect(data['primary_entity']['name']).to eq('Eugene Leontev')
      expect(data['primary_entity']['type']).to eq('Person')
    end

    it 'includes topic entities' do
      data = JSON.parse(entity_map_page.content)
      names = data['entities'].map { |e| e['name'] }
      expect(names).to include('PostgreSQL', 'Ruby on Rails')
    end
  end
end
