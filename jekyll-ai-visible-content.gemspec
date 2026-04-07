# frozen_string_literal: true

require_relative 'lib/jekyll_ai_visible_content/version'

Gem::Specification.new do |spec|
  spec.name          = 'jekyll-ai-visible-content'
  spec.version       = JekyllAiVisibleContent::VERSION
  spec.authors       = ['madmatvey']
  spec.email         = ['potehin@gmail.com']

  spec.summary       = 'Jekyll plugin that maximizes AI search discoverability'
  spec.description   = 'Adds rich JSON-LD structured data, llms.txt, semantic HTML helpers, ' \
                       'entity identity management, and AI crawler policies to Jekyll sites.'
  spec.homepage      = 'https://github.com/madmatvey/jekyll-ai-visible-content'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0'
  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:spec|\.github)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'jekyll', '>= 4.0', '< 5.0'

  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
end
