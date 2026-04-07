# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAiVisibleContent::Generators::LlmsTxtGenerator do
  let(:site) do
    s = make_site
    s.process
    s
  end

  describe "llms.txt generation" do
    it "generates llms.txt page" do
      llms_page = site.pages.find { |p| p.name == "llms.txt" }
      expect(llms_page).not_to be_nil
    end

    it "includes entity name in title" do
      llms_page = site.pages.find { |p| p.name == "llms.txt" }
      expect(llms_page.content).to include("# Test Site")
    end

    it "includes entity description" do
      llms_page = site.pages.find { |p| p.name == "llms.txt" }
      expect(llms_page.content).to include("Backend engineer")
    end

    it "includes topics section" do
      llms_page = site.pages.find { |p| p.name == "llms.txt" }
      expect(llms_page.content).to include("Ruby on Rails")
      expect(llms_page.content).to include("PostgreSQL")
    end

    it "includes posts" do
      llms_page = site.pages.find { |p| p.name == "llms.txt" }
      expect(llms_page.content).to include("Optimizing PostgreSQL Queries")
    end

    it "includes links section" do
      llms_page = site.pages.find { |p| p.name == "llms.txt" }
      expect(llms_page.content).to include("LinkedIn")
      expect(llms_page.content).to include("GitHub")
    end
  end

  describe "llms-full.txt generation" do
    it "generates llms-full.txt page" do
      full_page = site.pages.find { |p| p.name == "llms-full.txt" }
      expect(full_page).not_to be_nil
    end

    it "includes full post content" do
      full_page = site.pages.find { |p| p.name == "llms-full.txt" }
      expect(full_page.content).to include("optimizing PostgreSQL queries")
    end
  end
end
