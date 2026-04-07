# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::ContentFilter do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }

  describe '.content_page?' do
    it 'accepts HTML pages with layout' do
      page = make_page(site, title: 'About', layout: 'default')
      allow(page).to receive(:url).and_return('/about/')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, config)).to be true
    end

    it 'rejects JavaScript files' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/assets/js/app.js')
      allow(page).to receive(:name).and_return('app.js')
      allow(page).to receive(:output_ext).and_return('.js')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects CSS files' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/assets/css/style.css')
      allow(page).to receive(:name).and_return('style.css')
      allow(page).to receive(:output_ext).and_return('.css')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects generated llms.txt' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/llms.txt')
      allow(page).to receive(:name).and_return('llms.txt')
      allow(page).to receive(:output_ext).and_return('.txt')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects generated robots.txt' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/robots.txt')
      allow(page).to receive(:name).and_return('robots.txt')
      allow(page).to receive(:output_ext).and_return('.txt')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects entity-map.json' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/entity-map.json')
      allow(page).to receive(:name).and_return('entity-map.json')
      allow(page).to receive(:output_ext).and_return('.json')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects sitemap.xml' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/sitemap.xml')
      allow(page).to receive(:name).and_return('sitemap.xml')
      allow(page).to receive(:output_ext).and_return('.xml')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects 404.html' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/404.html')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects tag index pages' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/tags/ruby-on-rails/')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects category index pages' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/categories/coding/')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects pagination pages' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/page2/')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects redirect pages' do
      page = make_page(site, redirect_to: '/new-url/')
      allow(page).to receive(:url).and_return('/old-url/')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'rejects asset paths' do
      page = make_page(site)
      allow(page).to receive(:url).and_return('/assets/img/photo.html')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, config)).to be false
    end

    it 'respects exclude_paths config' do
      site_with_excludes = make_site(
        'ai_visible_content' => {
          'entity' => { 'name' => 'Test' },
          'validation' => { 'exclude_paths' => ['/custom/*'] }
        }
      )
      cfg = JekyllAiVisibleContent::Configuration.new(site_with_excludes)

      page = make_page(site_with_excludes, title: 'Custom Page')
      allow(page).to receive(:url).and_return('/custom/page/')
      allow(page).to receive(:output_ext).and_return('.html')
      expect(described_class.content_page?(page, cfg)).to be false
    end
  end

  describe '.content_pages' do
    let(:processed_site) do
      s = make_site
      s.process
      s
    end

    it 'includes posts' do
      pages = described_class.content_pages(processed_site, config)
      urls = pages.map(&:url)
      post_urls = urls.select { |u| u.include?('postgresql') || u.include?('rails') }
      expect(post_urls.size).to eq(2)
    end

    it 'includes about page' do
      pages = described_class.content_pages(processed_site, config)
      urls = pages.map(&:url)
      expect(urls).to include('/about/')
    end

    it 'excludes generated files' do
      pages = described_class.content_pages(processed_site, config)
      names = pages.select { |p| p.respond_to?(:name) }.map(&:name)
      expect(names).not_to include('llms.txt', 'robots.txt', 'entity-map.json')
    end
  end
end
