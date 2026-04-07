# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAiVisibleContent::JsonLd::FaqSchema do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }

  describe "#build" do
    context "with FAQ data" do
      let(:page) do
        p = make_page(site, faq: [
          { "question" => "What is Ruby?", "answer" => "A programming language." },
          { "question" => "What is Rails?", "answer" => "A web framework." }
        ])
        p
      end
      let(:schema) { described_class.new(config, page) }

      it "returns FAQPage" do
        result = schema.build
        expect(result["@type"]).to eq("FAQPage")
      end

      it "includes questions" do
        result = schema.build
        questions = result["mainEntity"]
        expect(questions.size).to eq(2)
        expect(questions.first["@type"]).to eq("Question")
        expect(questions.first["name"]).to eq("What is Ruby?")
      end

      it "includes answers" do
        result = schema.build
        answer = result["mainEntity"].first["acceptedAnswer"]
        expect(answer["@type"]).to eq("Answer")
        expect(answer["text"]).to eq("A programming language.")
      end
    end

    context "without FAQ data" do
      let(:page) { make_page(site) }
      let(:schema) { described_class.new(config, page) }

      it "returns nil" do
        expect(schema.build).to be_nil
      end
    end
  end
end
