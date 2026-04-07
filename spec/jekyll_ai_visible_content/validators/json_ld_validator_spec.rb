# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAiVisibleContent::Validators::JsonLdValidator do
  describe "#validate" do
    context "with valid entity config" do
      let(:site) { make_site }
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config) }

      it "returns no errors" do
        expect(validator.validate).to be_empty
      end
    end

    context "with missing entity name" do
      let(:site) { make_site("ai_visible_content" => { "entity" => { "name" => nil } }) }
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config) }

      it "returns error about missing name" do
        errors = validator.validate
        expect(errors.any? { |e| e.include?("name is required") }).to be true
      end
    end
  end

  describe "#validate_node" do
    let(:site) { make_site }
    let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
    let(:validator) { described_class.new(config) }

    it "validates Person node" do
      node = { "@type" => "Person", "@id" => "test", "name" => "Test" }
      expect(validator.validate_node(node)).to be_empty
    end

    it "reports missing Person fields" do
      node = { "@type" => "Person" }
      errors = validator.validate_node(node)
      expect(errors.any? { |e| e.include?("@id") }).to be true
    end

    it "validates BlogPosting node" do
      node = { "@type" => "BlogPosting", "headline" => "Test", "author" => { "@id" => "x" } }
      expect(validator.validate_node(node)).to be_empty
    end
  end
end
