# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::JsonLd::BreadcrumbSchema do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }

  describe '#build' do
    context 'with a multi-segment URL' do
      let(:page) do
        p = make_page(site, title: 'Test Post')
        allow(p).to receive(:url).and_return('/blog/2025/test-post/')
        p
      end
      let(:schema) { described_class.new(config, page) }

      it 'returns BreadcrumbList' do
        result = schema.build
        expect(result['@type']).to eq('BreadcrumbList')
      end

      it 'includes Home as first item' do
        result = schema.build
        items = result['itemListElement']
        expect(items.first['name']).to eq('Home')
        expect(items.first['position']).to eq(1)
      end

      it 'includes intermediate segments' do
        result = schema.build
        items = result['itemListElement']
        expect(items[1]['name']).to eq('Blog')
      end

      it 'uses page title for last segment' do
        result = schema.build
        items = result['itemListElement']
        expect(items.last['name']).to eq('Test Post')
      end
    end

    context 'with root URL' do
      let(:page) do
        p = make_page(site)
        allow(p).to receive(:url).and_return('/')
        p
      end
      let(:schema) { described_class.new(config, page) }

      it 'returns nil for root page' do
        expect(schema.build).to be_nil
      end
    end
  end
end
