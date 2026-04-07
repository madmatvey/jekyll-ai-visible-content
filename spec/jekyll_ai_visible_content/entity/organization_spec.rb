# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAiVisibleContent::Entity::Organization do
  let(:site) do
    make_site("ai_visible_content" => {
                "entity" => {
                  "type" => "Organization",
                  "id_slug" => "acme-corp",
                  "name" => "Acme Corp",
                  "description" => "A technology company.",
                  "image" => "/assets/img/logo.png",
                  "location" => { "locality" => "San Francisco", "country" => "US" },
                  "same_as" => ["https://linkedin.com/company/acme"]
                }
              })
  end
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
  let(:org) { described_class.new(config) }

  describe "#to_hash" do
    subject(:hash) { org.to_hash }

    it "sets @type to Organization" do
      expect(hash["@type"]).to eq("Organization")
    end

    it "sets @id" do
      expect(hash["@id"]).to eq("https://example.com/#acme-corp")
    end

    it "includes logo as ImageObject" do
      expect(hash["logo"]["@type"]).to eq("ImageObject")
    end

    it "includes address" do
      expect(hash["address"]["addressLocality"]).to eq("San Francisco")
    end

    it "includes sameAs" do
      expect(hash["sameAs"]).to include("https://linkedin.com/company/acme")
    end
  end
end
