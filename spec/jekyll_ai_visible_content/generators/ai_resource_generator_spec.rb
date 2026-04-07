# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Generators::AiResourceGenerator do
  let(:site) do
    s = make_site
    s.process
    s
  end

  describe 'AI resource file generation' do
    it 'generates JSON files under /ai/' do
      ai_pages = site.pages.select { |p| p.url.start_with?('/ai/') && p.url.end_with?('.json') }
      expect(ai_pages).not_to be_empty
    end

    it 'generates YAML files under /ai/' do
      ai_pages = site.pages.select { |p| p.url.start_with?('/ai/') && p.url.end_with?('.yml') }
      expect(ai_pages).not_to be_empty
    end

    it 'generates Markdown files under /ai/' do
      ai_pages = site.pages.select { |p| p.url.start_with?('/ai/') && p.url.end_with?('.md') }
      expect(ai_pages).not_to be_empty
    end

    it 'generates person resource for primary entity' do
      person_json = site.pages.find { |p| p.url.include?('/ai/person/eugene-leontev.json') }
      expect(person_json).not_to be_nil
      data = JSON.parse(person_json.content)
      expect(data['@type']).to eq('Person')
      expect(data['name']).to eq('Eugene Leontev')
    end

    it 'includes person metadata in person resource' do
      person_json = site.pages.find { |p| p.url.include?('/ai/person/eugene-leontev.json') }
      data = JSON.parse(person_json.content)
      expect(data['jobTitle']).to eq('Senior Backend Engineer / Fractional CTO')
      expect(data['sameAs']).to include('https://github.com/test-handle')
    end

    it 'generates topic resources for knows_about topics' do
      pg_json = site.pages.find { |p| p.url.include?('/ai/topic/postgresql.json') }
      expect(pg_json).not_to be_nil
      data = JSON.parse(pg_json.content)
      expect(data['@type']).to eq('Thing')
      expect(data['name']).to eq('PostgreSQL')
    end

    it 'tracks mentioning pages in resource data' do
      pg_json = site.pages.find { |p| p.url.include?('/ai/topic/postgresql.json') }
      data = JSON.parse(pg_json.content)
      urls = data['mentions_on'].map { |m| m['url'] }
      expect(urls).not_to be_empty
    end

    it 'sets layout to nil and sitemap to false on generated pages' do
      ai_pages = site.pages.select { |p| p.url.start_with?('/ai/') }
      ai_pages.each do |page|
        expect(page.data['layout']).to be_nil
        expect(page.data['sitemap']).to be false
      end
    end
  end

  describe 'site.data population' do
    it 'populates ai_page_resources mapping' do
      expect(site.data['ai_page_resources']).to be_a(Hash)
      expect(site.data['ai_page_resources']).not_to be_empty
    end

    it 'maps page URLs to resource paths' do
      about_resources = site.data['ai_page_resources']['/about/']
      expect(about_resources).to be_a(Array)
      expect(about_resources).not_to be_empty
      expect(about_resources.any? { |p| p.include?('/ai/person/') }).to be true
    end

    it 'populates ai_entity_resources mapping' do
      expect(site.data['ai_entity_resources']).to be_a(Hash)
      expect(site.data['ai_entity_resources']).not_to be_empty
    end
  end

  describe 'YAML resource content' do
    it 'generates valid YAML' do
      pg_yml = site.pages.find { |p| p.url.include?('/ai/topic/postgresql.yml') }
      expect(pg_yml).not_to be_nil
      data = YAML.safe_load(pg_yml.content)
      expect(data['name']).to eq('PostgreSQL')
    end
  end

  describe 'Markdown resource content' do
    it 'generates readable content with heading' do
      pg_md = site.pages.find { |p| p.url.include?('/ai/topic/postgresql.md') }
      expect(pg_md).not_to be_nil
      rendered = pg_md.output || pg_md.content
      expect(rendered).to include('PostgreSQL')
      expect(rendered).to include('Type')
    end
  end
end
