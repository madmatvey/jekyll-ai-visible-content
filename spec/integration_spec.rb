# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Integration: full site build', :integration do
  let(:site) do
    s = make_site
    s.process
    s
  end

  describe 'generated pages' do
    it 'generates llms.txt' do
      page = site.pages.find { |p| p.name == 'llms.txt' }
      expect(page).not_to be_nil
      expect(page.content).to include('Test Site')
      expect(page.content).to include('PostgreSQL')
    end

    it 'generates llms-full.txt with post bodies' do
      page = site.pages.find { |p| p.name == 'llms-full.txt' }
      expect(page).not_to be_nil
      expect(page.content).to include('optimizing PostgreSQL queries')
    end

    it 'generates robots.txt with AI crawler rules' do
      page = site.pages.find { |p| p.name == 'robots.txt' }
      expect(page).not_to be_nil
      expect(page.content).to include('GPTBot')
      expect(page.content).to include('PerplexityBot')
      expect(page.content).to include('ClaudeBot')
      expect(page.content).to include('Sitemap:')
    end

    it 'generates entity-map.json' do
      page = site.pages.find { |p| p.name == 'entity-map.json' }
      expect(page).not_to be_nil
      data = JSON.parse(page.content)
      expect(data['primary_entity']['name']).to eq('Eugene Leontev')
    end
  end

  describe 'post processing' do
    it 'processes posts without errors' do
      expect(site.posts.docs.size).to eq(2)
    end

    it 'preserves post content' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.content).to include('optimizing PostgreSQL queries')
    end
  end

  describe 'JSON-LD auto-injection' do
    it 'injects JSON-LD into about page HTML' do
      about = site.pages.find { |p| p.url == '/about/' }
      expect(about.output).to include('application/ld+json')
      expect(about.output).to include('"Person"')
    end

    it 'injects BlogPosting JSON-LD into post HTML' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.output).to include('application/ld+json')
      expect(post.output).to include('"BlogPosting"')
    end

    it 'includes entity @id in post JSON-LD' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.output).to include('eugene-leontev')
    end

    it 'includes FAQPage when faq is in front matter' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.output).to include('"FAQPage"')
    end

    it 'includes BreadcrumbList' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.output).to include('"BreadcrumbList"')
    end
  end

  describe 'entity auto-linking' do
    it 'links known entities in post content' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.output).to include('itemprop="about"')
      expect(post.output).to include('/topics/ruby-on-rails/')
    end
  end

  describe 'content graph' do
    it 'populates ai_content_graph data' do
      expect(site.data['ai_content_graph']).to be_a(Hash)
    end

    it 'only tracks content pages in orphan detection' do
      orphans = site.data['ai_orphan_pages']
      orphan_generated = orphans.grep(/llms\.txt|robots\.txt|entity-map/)
      expect(orphan_generated).to be_empty
    end

    it 'does not report posts as orphan when linked only via Liquid-rendered index' do
      orphans = site.data['ai_orphan_pages']
      post_urls = site.posts.docs.map(&:url)
      expect(orphans & post_urls).to be_empty
    end

    it 'normalizes query/hash/index links into canonical inbound entries' do
      graph = site.data['ai_content_graph']
      post = site.posts.docs.find { |p| p.url.include?('optimizing-postgresql-queries') }
      expect(graph[post.url]['inbound']).to include('/')
    end
  end

  describe 'content filtering' do
    it 'does not include generated files in content pages' do
      config = JekyllAiVisibleContent.config(site)
      content = JekyllAiVisibleContent::ContentFilter.content_pages(site, config)
      names = content.select { |p| p.respond_to?(:name) }.map(&:name)
      expect(names).not_to include('llms.txt', 'robots.txt', 'entity-map.json')
    end

    it 'includes authored HTML pages in content pages' do
      config = JekyllAiVisibleContent.config(site)
      content = JekyllAiVisibleContent::ContentFilter.content_pages(site, config)
      urls = content.map(&:url)
      expect(urls).to include('/about/')
    end
  end

  describe 'entity-map.json content' do
    it 'does not inflate counts from generated files' do
      page = site.pages.find { |p| p.name == 'entity-map.json' }
      data = JSON.parse(page.content)
      pg_entity = data['entities'].find { |e| e['name'] == 'PostgreSQL' }
      expect(pg_entity['linked_posts']).not_to include('/llms.txt', '/llms-full.txt')
    end
  end

  describe 'AI resource generation' do
    it 'generates /ai/person/*.json for the primary entity' do
      person_json = site.pages.find { |p| p.url.include?('/ai/person/eugene-leontev.json') }
      expect(person_json).not_to be_nil
    end

    it 'generates /ai/topic/*.json for knows_about topics' do
      pg_json = site.pages.find { |p| p.url.include?('/ai/topic/postgresql.json') }
      expect(pg_json).not_to be_nil
    end

    it 'generates YAML and Markdown variants' do
      pg_yml = site.pages.find { |p| p.url.include?('/ai/topic/postgresql.yml') }
      pg_md = site.pages.find { |p| p.url.include?('/ai/topic/postgresql.md') }
      expect(pg_yml).not_to be_nil
      expect(pg_md).not_to be_nil
    end

    it 'injects link tags before </body>' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.output).to include('rel="ai:json"')
      expect(post.output).to include('rel="ai:yaml"')
      expect(post.output).to include('rel="ai:markdown"')
    end

    it 'injects AI instruction block before </body>' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      expect(post.output).to include('AI: LLM INSTRUCTION')
      expect(post.output).to include('PRIORITY PARSING MODE')
    end

    it 'does not duplicate instruction block in nested layouts' do
      post = site.posts.docs.find { |p| p.url.include?('postgresql') }
      occurrences = post.output.scan('AI: LLM INSTRUCTION').size
      expect(occurrences).to eq(1)
    end

    it 'places link tags before </body>' do
      about = site.pages.find { |p| p.url == '/about/' }
      body_close_idx = about.output.index('</body>')
      link_idx = about.output.index('rel="ai:json"')
      expect(link_idx).to be < body_close_idx
    end

    it 'does not include /ai/ paths in content pages' do
      config = JekyllAiVisibleContent.config(site)
      content = JekyllAiVisibleContent::ContentFilter.content_pages(site, config)
      ai_pages = content.select { |p| p.url.to_s.start_with?('/ai/') }
      expect(ai_pages).to be_empty
    end
  end

  describe 'llms.txt structure' do
    let(:llms_page) { site.pages.find { |p| p.name == 'llms.txt' } }

    it 'has title header' do
      expect(llms_page.content).to start_with('# ')
    end

    it 'has About section' do
      expect(llms_page.content).to include('## About')
    end

    it 'has Key Topics section' do
      expect(llms_page.content).to include('## Key Topics')
    end

    it 'has Posts section' do
      expect(llms_page.content).to include('## Posts')
    end

    it 'has Links section' do
      expect(llms_page.content).to include('## Links')
    end
  end
end
