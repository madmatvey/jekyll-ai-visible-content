# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Generators::LlmsTxtGenerator do
  let(:site) do
    s = make_site
    s.process
    s
  end

  describe 'llms.txt generation' do
    it 'generates llms.txt page' do
      llms_page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(llms_page).not_to be_nil
    end

    it 'includes entity name in title' do
      llms_page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(llms_page.content).to include('# Test Site')
    end

    it 'includes entity description' do
      llms_page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(llms_page.content).to include('Backend engineer')
    end

    it 'includes topics section' do
      llms_page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(llms_page.content).to include('Ruby on Rails')
      expect(llms_page.content).to include('PostgreSQL')
    end

    it 'includes posts' do
      llms_page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(llms_page.content).to include('Optimizing PostgreSQL Queries')
    end

    it 'includes custom collection documents' do
      llms_page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(llms_page.content).to include('## Guides')
      expect(llms_page.content).to include('Custom Collection Docs')
      expect(llms_page.content).to include('/guides/custom-collections/')
    end

    context 'when markdown_urls is enabled' do
      let(:site) do
        s = make_site
        s.config['ai_visible_content']['llms_txt']['markdown_urls'] = true
        s.process
        s
      end

      it 'links content entries to Markdown siblings' do
        llms_page = site.pages.find { |p| p.name == 'llms.txt' }
        expect(llms_page.content).to include('https://example.com/guides/custom-collections.md')
        expect(llms_page.content).not_to include('https://example.com/guides/custom-collections/')
      end
    end

    it 'includes links section' do
      llms_page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(llms_page.content).to include('LinkedIn')
      expect(llms_page.content).to include('GitHub')
    end
  end

  describe 'llms-full.txt generation' do
    it 'generates llms-full.txt page' do
      full_page = site.pages.find { |p| p.name == 'llms-full.txt' }
      expect(full_page).not_to be_nil
    end

    it 'includes full post content' do
      full_page = site.pages.find { |p| p.name == 'llms-full.txt' }
      expect(full_page.content).to include('optimizing PostgreSQL queries')
    end

    it 'includes full custom collection content' do
      full_page = site.pages.find { |p| p.name == 'llms-full.txt' }
      expect(full_page.content).to include('Custom collection documentation should appear')
    end

    it 'renders Liquid in full custom collection content' do
      full_page = site.pages.find { |p| p.name == 'llms-full.txt' }
      expect(full_page.content).to include('# Custom Collection Docs')
      expect(full_page.content).to include('[this guide](/guides/custom-collections/)')
      expect(full_page.content).not_to include('{{ page.title }}')
      expect(full_page.content).not_to include('{% link')
    end

    it 'preserves code examples with angle brackets' do
      full_page = site.pages.find { |p| p.name == 'llms-full.txt' }
      expect(full_page.content).to include('class CustomCollectionDoc < ApplicationRecord')
      expect(full_page.content).to include('<%= target_id %>')
    end
  end
end
