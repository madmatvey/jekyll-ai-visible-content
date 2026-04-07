# frozen_string_literal: true

module JekyllAiVisibleContent
  module Hooks
    module ValidateHook
      WARNING_GROUPS = {
        'Name inconsistency' => 'name inconsistency warnings (configure entity.author_aliases)',
        'Missing last_modified_at' => 'posts missing last_modified_at (freshness scoring disabled)',
        'Missing description' => 'content pages missing description',
        'Generic title' => 'pages with generic titles',
        'Orphan page' => 'orphan pages with no inbound links',
        'Entity has no sameAs' => 'entity missing sameAs links'
      }.freeze

      class << self
        def register!
          Jekyll::Hooks.register(:site, :post_write) { |site| validate(site) }
        end

        private

        def validate(site)
          config = JekyllAiVisibleContent.config(site)
          return unless config.enabled?

          refresh_rendered_link_graph(site, config)

          warnings = []
          errors = []

          entity_validator = Validators::EntityConsistencyValidator.new(config, site)
          warnings.concat(entity_validator.validate)

          json_ld_validator = Validators::JsonLdValidator.new(config)
          errors.concat(json_ld_validator.validate)

          link_validator = Validators::LinkValidator.new(config, site)
          warnings.concat(link_validator.validate)

          print_results(warnings, errors, config)
          abort_if_needed(errors) if config.validation['fail_build_on_error'] && errors.any?
        end

        def refresh_rendered_link_graph(site, config)
          generator = Generators::ContentGraphGenerator.new
          docs = ContentFilter.content_pages(site, config)
          graph = generator.send(:build_link_graph, docs, config)
          orphans = generator.send(:find_orphans, graph, docs)

          site.data['ai_content_graph'] = graph
          site.data['ai_orphan_pages'] = orphans
        end

        def print_results(warnings, errors, config)
          return if warnings.empty? && errors.empty?

          Jekyll.logger.info 'AI Visible Content:', '=== Validation Report ==='

          if config.validation['verbose']
            print_verbose(warnings, errors)
          else
            print_grouped(warnings, errors, config)
          end
        end

        def print_verbose(warnings, errors)
          warnings.each { |w| Jekyll.logger.warn 'AI Visible Content:', w }
          errors.each { |e| Jekyll.logger.error 'AI Visible Content:', e }
        end

        def print_grouped(warnings, errors, config)
          max_examples = config.validation['max_examples'] || 3
          groups = group_warnings(warnings)

          groups.each do |label, items|
            Jekyll.logger.warn 'AI Visible Content:', "#{items.size} #{label}"
            items.first(max_examples).each do |item|
              Jekyll.logger.warn 'AI Visible Content:', "  #{item}"
            end
            remaining = items.size - max_examples
            Jekyll.logger.warn('AI Visible Content:', "  ... and #{remaining} more") if remaining.positive?
          end

          errors.each { |e| Jekyll.logger.error 'AI Visible Content:', e }
        end

        def group_warnings(warnings)
          groups = {}

          warnings.each do |warning|
            key = find_group_key(warning)
            label = WARNING_GROUPS[key] || key
            groups[label] ||= []
            groups[label] << warning
          end

          groups
        end

        def find_group_key(warning)
          WARNING_GROUPS.each_key do |prefix|
            return prefix if warning.start_with?(prefix)
          end
          'other warnings'
        end

        def abort_if_needed(errors)
          raise JekyllAiVisibleContent::Error, "Build failed: #{errors.size} validation error(s)" if errors.any?
        end
      end
    end
  end
end

JekyllAiVisibleContent::Hooks::ValidateHook.register!
