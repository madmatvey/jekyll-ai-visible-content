# frozen_string_literal: true

module JekyllAiVisibleContent
  class Configuration
    CONFIG_KEY = 'ai_visible_content'

    DEFAULTS = {
      'enabled' => true,
      'entity' => {
        'type' => 'Person',
        'id_slug' => nil,
        'name' => nil,
        'alternate_names' => [],
        'job_title' => nil,
        'description' => nil,
        'image' => nil,
        'email' => nil,
        'location' => { 'locality' => nil, 'country' => nil },
        'knows_about' => [],
        'same_as' => [],
        'works_for' => nil,
        'occupation' => nil
      },
      'json_ld' => {
        'auto_inject' => true,
        'include_website_schema' => true,
        'include_breadcrumbs' => true,
        'include_blog_posting' => true,
        'include_faq' => true,
        'include_how_to' => true,
        'article_body' => 'excerpt',
        'compact' => false
      },
      'crawlers' => {
        'allow_gptbot' => true,
        'allow_perplexitybot' => true,
        'allow_claudebot' => true,
        'allow_googlebot' => true,
        'allow_bingbot' => true,
        'custom_rules' => [],
        'generate_robots_txt' => true
      },
      'llms_txt' => {
        'enabled' => true,
        'title' => nil,
        'description' => nil,
        'sections' => [],
        'include_full_text' => true
      },
      'linking' => {
        'enable_entity_links' => true,
        'entity_definitions' => {},
        'max_links_per_entity_per_post' => 1,
        'enable_related_posts' => true,
        'related_posts_limit' => 3
      },
      'validation' => {
        'warn_name_inconsistency' => true,
        'warn_missing_same_as' => true,
        'warn_missing_dates' => true,
        'warn_orphan_pages' => true,
        'warn_missing_descriptions' => true,
        'fail_build_on_error' => false
      }
    }.freeze

    attr_reader :site

    def initialize(site)
      @site = site
      @raw = deep_merge(DEFAULTS, site.config.fetch(CONFIG_KEY, {}))
    end

    def enabled?
      @raw['enabled'] == true
    end

    def entity
      @raw['entity']
    end

    def entity_id
      slug = entity['id_slug'] || entity['name']&.downcase&.gsub(/[^a-z0-9]+/, '-')&.gsub(/(^-|-$)/, '')
      "#{site_url}/##{slug}" if slug
    end

    def entity_type
      entity['type'] || 'Person'
    end

    def json_ld
      @raw['json_ld']
    end

    def crawlers
      @raw['crawlers']
    end

    def llms_txt
      @raw['llms_txt']
    end

    def linking
      @raw['linking']
    end

    def validation
      @raw['validation']
    end

    def site_url
      @site.config['url'] || ''
    end

    def site_title
      @site.config['title'] || entity['name'] || ''
    end

    def site_description
      @site.config['description'] || entity['description'] || ''
    end

    def seo_tag_present?
      @site.config['plugins']&.include?('jekyll-seo-tag') ||
        Gem.loaded_specs.key?('jekyll-seo-tag')
    rescue StandardError
      false
    end

    def [](key)
      @raw[key]
    end

    private

    def deep_merge(base, override)
      base.each_with_object(base.dup) do |(key, base_val), result|
        next unless override.key?(key)

        result[key] = if base_val.is_a?(Hash) && override[key].is_a?(Hash)
                        deep_merge(base_val, override[key])
                      else
                        override[key]
                      end
      end.merge(override.reject { |k, _| base.key?(k) })
    end
  end
end
