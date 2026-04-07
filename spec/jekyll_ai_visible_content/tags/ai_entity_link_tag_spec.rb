# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Tags::AiEntityLinkTag do
  let(:site) { make_site }

  it 'is registered as ai_entity_link tag' do
    expect(Liquid::Template.tags['ai_entity_link']).to eq(described_class)
  end

  describe 'rendering' do
    it 'renders semantic link for known entity' do
      template = Liquid::Template.parse('{% ai_entity_link "Ruby on Rails" %}')
      context = Liquid::Context.new({}, {}, { site: site })
      output = template.render(context)
      expect(output).to include('Ruby on Rails')
      expect(output).to include('itemprop="about"')
      expect(output).to include('/topics/ruby-on-rails/')
    end

    it 'renders plain text for unknown entity' do
      template = Liquid::Template.parse('{% ai_entity_link "Unknown Framework" %}')
      context = Liquid::Context.new({}, {}, { site: site })
      output = template.render(context)
      expect(output).to eq('Unknown Framework')
    end
  end
end
