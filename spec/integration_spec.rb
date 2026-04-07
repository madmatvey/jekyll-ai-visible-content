# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Integration: full site build", :integration do
  let(:site) do
    s = make_site
    s.process
    s
  end

  describe "generated pages" do
    it "generates llms.txt" do
      page = site.pages.find { |p| p.name == "llms.txt" }
      expect(page).not_to be_nil
      expect(page.content).to include("Test Site")
      expect(page.content).to include("PostgreSQL")
    end

    it "generates llms-full.txt with post bodies" do
      page = site.pages.find { |p| p.name == "llms-full.txt" }
      expect(page).not_to be_nil
      expect(page.content).to include("optimizing PostgreSQL queries")
    end

    it "generates robots.txt with AI crawler rules" do
      page = site.pages.find { |p| p.name == "robots.txt" }
      expect(page).not_to be_nil
      expect(page.content).to include("GPTBot")
      expect(page.content).to include("PerplexityBot")
      expect(page.content).to include("ClaudeBot")
      expect(page.content).to include("Sitemap:")
    end

    it "generates entity-map.json" do
      page = site.pages.find { |p| p.name == "entity-map.json" }
      expect(page).not_to be_nil
      data = JSON.parse(page.content)
      expect(data["primary_entity"]["name"]).to eq("Eugene Leontev")
    end
  end

  describe "post processing" do
    it "processes posts without errors" do
      expect(site.posts.docs.size).to eq(2)
    end

    it "preserves post content" do
      post = site.posts.docs.find { |p| p.url.include?("postgresql") }
      expect(post.content).to include("optimizing PostgreSQL queries")
    end
  end

  describe "JSON-LD auto-injection" do
    it "injects JSON-LD into about page HTML" do
      about = site.pages.find { |p| p.url == "/about/" }
      expect(about.output).to include("application/ld+json")
      expect(about.output).to include('"Person"')
    end

    it "injects BlogPosting JSON-LD into post HTML" do
      post = site.posts.docs.find { |p| p.url.include?("postgresql") }
      expect(post.output).to include("application/ld+json")
      expect(post.output).to include('"BlogPosting"')
    end

    it "includes entity @id in post JSON-LD" do
      post = site.posts.docs.find { |p| p.url.include?("postgresql") }
      expect(post.output).to include("eugene-leontev")
    end

    it "includes FAQPage when faq is in front matter" do
      post = site.posts.docs.find { |p| p.url.include?("postgresql") }
      expect(post.output).to include('"FAQPage"')
    end

    it "includes BreadcrumbList" do
      post = site.posts.docs.find { |p| p.url.include?("postgresql") }
      expect(post.output).to include('"BreadcrumbList"')
    end
  end

  describe "entity auto-linking" do
    it "links known entities in post content" do
      post = site.posts.docs.find { |p| p.url.include?("postgresql") }
      expect(post.output).to include('itemprop="about"')
      expect(post.output).to include("/topics/ruby-on-rails/")
    end
  end

  describe "content graph" do
    it "populates ai_content_graph data" do
      expect(site.data["ai_content_graph"]).to be_a(Hash)
    end
  end

  describe "llms.txt structure" do
    let(:llms_page) { site.pages.find { |p| p.name == "llms.txt" } }

    it "has title header" do
      expect(llms_page.content).to start_with("# ")
    end

    it "has About section" do
      expect(llms_page.content).to include("## About")
    end

    it "has Key Topics section" do
      expect(llms_page.content).to include("## Key Topics")
    end

    it "has Posts section" do
      expect(llms_page.content).to include("## Posts")
    end

    it "has Links section" do
      expect(llms_page.content).to include("## Links")
    end
  end
end
