# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAiVisibleContent::Tags::AiAuthorTag do
  let(:site) { make_site }

  it "is registered as ai_author tag" do
    expect(Liquid::Template.tags["ai_author"]).to eq(described_class)
  end

  describe "rendering" do
    it "renders author span with schema markup" do
      template = Liquid::Template.parse("{% ai_author %}")
      context = Liquid::Context.new({}, {}, { site: site })
      output = template.render(context)
      expect(output).to include("Eugene Leontev")
      expect(output).to include('itemprop="author"')
      expect(output).to include('itemprop="name"')
      expect(output).to include("/about/")
    end
  end
end
