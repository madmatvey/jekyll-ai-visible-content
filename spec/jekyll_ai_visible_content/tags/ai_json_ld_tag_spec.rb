# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Tags::AiJsonLdTag do
  let(:site) do
    s = make_site
    s.process
    s
  end

  it 'is registered as ai_json_ld tag' do
    expect(Liquid::Template.tags['ai_json_ld']).to eq(described_class)
  end

  describe 'rendering' do
    it 'renders JSON-LD script tag for about page' do
      about = site.pages.find { |p| p.url == '/about/' }
      template = Liquid::Template.parse('{% ai_json_ld %}')
      context = make_liquid_context(site, about)
      output = template.render(context)
      expect(output).to include('application/ld+json')
      expect(output).to include('"@type"')
    end
  end

  private

  def make_liquid_context(site, page)
    Liquid::Context.new(
      {},
      {},
      { site: site, page: page.data.merge('url' => page.url) }
    )
  end
end
