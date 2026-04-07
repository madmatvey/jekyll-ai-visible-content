# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JekyllAiVisibleContent::Validators::EntityConsistencyValidator do
  describe '#validate' do
    context 'with consistent names' do
      let(:site) do
        s = make_site
        s.process
        s
      end
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config, site) }

      it 'returns no name inconsistency warnings' do
        warnings = validator.validate
        name_warnings = warnings.select { |w| w.include?('Name inconsistency') }
        expect(name_warnings).to be_empty
      end
    end

    context 'with inconsistent author name' do
      let(:site) do
        make_site(
          'author' => 'Wrong Name',
          'ai_visible_content' => {
            'entity' => { 'name' => 'Eugene Leontev' },
            'validation' => { 'warn_name_inconsistency' => true }
          }
        )
      end
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config, site) }

      it 'warns about name inconsistency' do
        warnings = validator.validate
        expect(warnings.any? { |w| w.include?('Name inconsistency') }).to be true
      end
    end

    context 'with author alias configured' do
      let(:site) do
        make_site(
          'author' => 'eugene',
          'ai_visible_content' => {
            'entity' => {
              'name' => 'Eugene Leontev',
              'author_aliases' => %w[eugene]
            },
            'validation' => { 'warn_name_inconsistency' => true }
          }
        )
      end
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config, site) }

      it 'does not warn when author matches an alias' do
        warnings = validator.validate
        name_warnings = warnings.select { |w| w.include?('Name inconsistency') }
        expect(name_warnings).to be_empty
      end
    end

    context 'with _data/authors.yml resolution' do
      let(:site) do
        s = make_site(
          'author' => 'eugene',
          'ai_visible_content' => {
            'entity' => { 'name' => 'Eugene Leontev' },
            'validation' => { 'warn_name_inconsistency' => true }
          }
        )
        s.process
        s
      end
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config, site) }

      it 'resolves author slug through authors data' do
        warnings = validator.validate
        name_warnings = warnings.select { |w| w.include?('site.author') }
        expect(name_warnings).to be_empty
      end
    end

    context 'with missing sameAs' do
      let(:site) do
        make_site('ai_visible_content' => {
                    'entity' => { 'name' => 'Test', 'same_as' => [] },
                    'validation' => { 'warn_missing_same_as' => true }
                  })
      end
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config, site) }

      it 'warns about missing sameAs' do
        warnings = validator.validate
        expect(warnings.any? { |w| w.include?('sameAs') }).to be true
      end
    end

    context 'with content_only filtering' do
      let(:site) do
        s = make_site
        s.process
        s
      end
      let(:config) { JekyllAiVisibleContent::Configuration.new(site) }
      let(:validator) { described_class.new(config, site) }

      it 'does not warn about missing descriptions on generated files' do
        warnings = validator.validate
        desc_warnings = warnings.select { |w| w.include?('Missing description') }
        generated = desc_warnings.grep(/llms\.txt|robots\.txt|entity-map\.json/)
        expect(generated).to be_empty
      end
    end
  end
end
