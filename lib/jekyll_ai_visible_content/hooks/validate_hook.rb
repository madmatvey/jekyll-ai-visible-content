# frozen_string_literal: true

module JekyllAiVisibleContent
  module Hooks
    module ValidateHook
      class << self
        def register!
          Jekyll::Hooks.register(:site, :post_write) { |site| validate(site) }
        end

        private

        def validate(site)
          config = JekyllAiVisibleContent.config(site)
          return unless config.enabled?

          warnings = []
          errors = []

          entity_validator = Validators::EntityConsistencyValidator.new(config, site)
          warnings.concat(entity_validator.validate)

          json_ld_validator = Validators::JsonLdValidator.new(config)
          errors.concat(json_ld_validator.validate)

          link_validator = Validators::LinkValidator.new(config, site)
          warnings.concat(link_validator.validate)

          print_results(warnings, errors)
          abort_if_needed(errors, config) if config.validation["fail_build_on_error"] && errors.any?
        end

        def print_results(warnings, errors)
          return if warnings.empty? && errors.empty?

          Jekyll.logger.info "AI Visible Content:", "Validation report"
          warnings.each { |w| Jekyll.logger.warn "AI Visible Content:", w }
          errors.each { |e| Jekyll.logger.error "AI Visible Content:", e }
        end

        def abort_if_needed(errors, _config)
          raise JekyllAiVisibleContent::Error, "Build failed: #{errors.size} validation error(s)" if errors.any?
        end
      end
    end
  end
end

JekyllAiVisibleContent::Hooks::ValidateHook.register!
