# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAiVisibleContent::Entity::Person do
  let(:site) { make_site }
  let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
  let(:person) { described_class.new(config) }

  describe "#to_hash" do
    subject(:hash) { person.to_hash }

    it "sets @type to Person" do
      expect(hash["@type"]).to eq("Person")
    end

    it "sets @id from config" do
      expect(hash["@id"]).to eq("https://example.com/#eugene-leontev")
    end

    it "sets name" do
      expect(hash["name"]).to eq("Eugene Leontev")
    end

    it "includes alternate names" do
      expect(hash["alternateName"]).to include("Евгений Леонтьев")
    end

    it "includes job title" do
      expect(hash["jobTitle"]).to eq("Senior Backend Engineer / Fractional CTO")
    end

    it "includes image as ImageObject" do
      expect(hash["image"]["@type"]).to eq("ImageObject")
      expect(hash["image"]["url"]).to eq("https://example.com/assets/img/eugene-leontev.jpg")
    end

    it "includes address" do
      expect(hash["address"]["addressLocality"]).to eq("Tbilisi")
      expect(hash["address"]["addressCountry"]).to eq("GE")
    end

    it "includes knowsAbout" do
      expect(hash["knowsAbout"]).to include("Ruby on Rails", "PostgreSQL", "AWS")
    end

    it "includes sameAs" do
      expect(hash["sameAs"]).to include("https://linkedin.com/in/test-handle")
    end

    it "includes worksFor" do
      expect(hash["worksFor"]["@type"]).to eq("Organization")
      expect(hash["worksFor"]["name"]).to eq("Freelance")
    end

    it "includes hasOccupation" do
      expect(hash["hasOccupation"]["@type"]).to eq("Occupation")
      expect(hash["hasOccupation"]["name"]).to eq("Backend Engineer")
    end
  end
end
