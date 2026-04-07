# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Generators::RobotsTxtGenerator do
  let(:site) do
    s = make_site
    s.process
    s
  end

  describe 'robots.txt generation' do
    let(:robots_page) { site.pages.find { |p| p.name == 'robots.txt' } }

    it 'generates robots.txt' do
      expect(robots_page).not_to be_nil
    end

    it 'includes wildcard allow' do
      expect(robots_page.content).to include('User-agent: *')
      expect(robots_page.content).to include('Allow: /')
    end

    it 'includes GPTBot' do
      expect(robots_page.content).to include('User-agent: GPTBot')
    end

    it 'includes PerplexityBot' do
      expect(robots_page.content).to include('User-agent: PerplexityBot')
    end

    it 'includes ClaudeBot' do
      expect(robots_page.content).to include('User-agent: ClaudeBot')
    end

    it 'includes sitemap' do
      expect(robots_page.content).to include('Sitemap: https://example.com/sitemap.xml')
    end
  end

  describe 'conflict detection' do
    it 'skips generation when robots.txt exists in source' do
      robots_path = File.join(FIXTURES_DIR, 'robots.txt')
      begin
        File.write(robots_path, "User-agent: *\nDisallow:")

        s = make_site
        s.process

        ai_generated = s.pages.select { |p| p.name == 'robots.txt' && p.is_a?(Jekyll::PageWithoutAFile) }
        expect(ai_generated).to be_empty
      ensure
        FileUtils.rm_f(robots_path)
      end
    end
  end
end
