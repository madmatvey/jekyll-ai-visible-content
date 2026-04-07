# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Generators::ContentGraphGenerator do
  let(:generator) { described_class.new }

  describe 'URL normalization' do
    it 'normalizes index.html to directory URL' do
      url = generator.send(:normalize_url, '/blog/index.html', 'https://example.com', '')
      expect(url).to eq('/blog/')
    end

    it 'strips query and fragment' do
      url = generator.send(:normalize_url, '/blog/post?ref=home#top', 'https://example.com', '')
      expect(url).to eq('/blog/post/')
    end

    it 'strips baseurl from internal links' do
      url = generator.send(:normalize_url, '/myblog/posts/abc', 'https://example.com', '/myblog')
      expect(url).to eq('/posts/abc/')
    end

    it 'normalizes absolute internal URLs' do
      url = generator.send(:normalize_url, 'https://example.com/posts/abc?x=1', 'https://example.com', '')
      expect(url).to eq('/posts/abc/')
    end

    it 'ignores external URLs' do
      url = generator.send(:normalize_url, 'https://external.example/posts/abc', 'https://example.com', '')
      expect(url).to be_nil
    end
  end
end
