# frozen_string_literal: true

require 'jekyll'
require 'json'

require_relative 'jekyll_ai_visible_content/version'
require_relative 'jekyll_ai_visible_content/configuration'
require_relative 'jekyll_ai_visible_content/content_filter'
require_relative 'jekyll_ai_visible_content/entity/person'
require_relative 'jekyll_ai_visible_content/entity/organization'
require_relative 'jekyll_ai_visible_content/entity/registry'
require_relative 'jekyll_ai_visible_content/json_ld/builder'
require_relative 'jekyll_ai_visible_content/json_ld/person_schema'
require_relative 'jekyll_ai_visible_content/json_ld/blog_posting_schema'
require_relative 'jekyll_ai_visible_content/json_ld/website_schema'
require_relative 'jekyll_ai_visible_content/json_ld/breadcrumb_schema'
require_relative 'jekyll_ai_visible_content/json_ld/faq_schema'
require_relative 'jekyll_ai_visible_content/json_ld/how_to_schema'
require_relative 'jekyll_ai_visible_content/json_ld/collection_schema'
require_relative 'jekyll_ai_visible_content/entity_classifier'
require_relative 'jekyll_ai_visible_content/generators/llms_txt_generator'
require_relative 'jekyll_ai_visible_content/generators/robots_txt_generator'
require_relative 'jekyll_ai_visible_content/generators/entity_map_generator'
require_relative 'jekyll_ai_visible_content/generators/content_graph_generator'
require_relative 'jekyll_ai_visible_content/generators/ai_resource_generator'
require_relative 'jekyll_ai_visible_content/tags/ai_json_ld_tag'
require_relative 'jekyll_ai_visible_content/tags/ai_author_tag'
require_relative 'jekyll_ai_visible_content/tags/ai_entity_link_tag'
require_relative 'jekyll_ai_visible_content/tags/ai_related_posts_tag'
require_relative 'jekyll_ai_visible_content/tags/ai_breadcrumb_tag'
require_relative 'jekyll_ai_visible_content/tags/ai_resource_links_tag'
require_relative 'jekyll_ai_visible_content/filters/naming_filter'
require_relative 'jekyll_ai_visible_content/filters/entity_filter'
require_relative 'jekyll_ai_visible_content/hooks/post_render_hook'
require_relative 'jekyll_ai_visible_content/hooks/validate_hook'
require_relative 'jekyll_ai_visible_content/validators/entity_consistency_validator'
require_relative 'jekyll_ai_visible_content/validators/json_ld_validator'
require_relative 'jekyll_ai_visible_content/validators/link_validator'

module JekyllAiVisibleContent
  class Error < StandardError; end

  def self.config(site)
    @configs ||= {}.compare_by_identity
    @configs[site] ||= Configuration.new(site)
  end

  def self.reset!
    @configs = {}.compare_by_identity
  end
end
