# frozen_string_literal: true

require "jekyll"
require "jekyll-ai-visible-content"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random

  FIXTURES_DIR = File.expand_path("fixtures", __dir__)

  def make_site(overrides = {})
    config = Jekyll.configuration(
      "source" => FIXTURES_DIR,
      "destination" => File.join(FIXTURES_DIR, "_site"),
      "url" => "https://example.com",
      "quiet" => true
    ).merge(overrides)
    Jekyll::Site.new(config)
  end

  def make_page(site, attrs = {})
    page = Jekyll::Page.new(site, site.source, "", "index.md")
    attrs.each { |k, v| page.data[k.to_s] = v }
    page
  end

  def make_post(site, name, attrs = {})
    collection = site.collections["posts"]
    path = File.join(site.source, "_posts", name)
    doc = Jekyll::Document.new(path, site: site, collection: collection)
    attrs.each { |k, v| doc.data[k.to_s] = v }
    doc
  end

  config.before(:each) do
    JekyllAiVisibleContent.reset!
  end
end
