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
  end
end
