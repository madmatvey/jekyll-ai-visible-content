# Changelog

## 0.4.0 (2026-04-07)

- Add automatic AI resource generation per content page with deterministic `/ai/<type>/<slug>.{json,yml,md}` outputs
- Add content-aware entity classification heuristics (person/entity/topic) from front matter and page content
- Inject `<link rel="ai:*">` tags and AI parsing instruction block before `</body>` in rendered HTML
- Add `{% ai_resource_links %}` Liquid fallback for manual layout integration
- Exclude generated `/ai/` resources from content filtering/orphan detection
- Add unit and integration coverage for AI resource generation and HTML injection flow

## 0.3.0 (2026-04-07)

- Fix false positives for orphan-page detection by analyzing rendered HTML instead of raw source content
- Build inbound-link graph from final `<a href>` values produced by Liquid/layout rendering
- Add canonical URL normalization for orphan analysis:
  - strip query strings and hash fragments
  - normalize `index.html` to directory URLs
  - normalize trailing slashes for non-file paths
  - resolve absolute internal URLs and handle `baseurl`
- Add regression tests for Liquid-generated links and URL normalization in content graph

## 0.2.0 (2026-04-07)

- Add shared content filtering module to reduce validator noise on assets/generated pages
- Improve entity consistency checks with `entity.author_aliases` and `_data/authors.yml` resolution
- Add robots.txt conflict detection to skip generation when a site already provides `robots.txt`
- Add grouped validation output with counts and configurable examples (`validation.max_examples`)
- Add new validation config defaults: `content_only`, `exclude_paths`, `verbose`, `max_examples`
- Filter entity-map mention scanning to authored content pages only

## 0.1.0

- Initial release
- JSON-LD generation: Person, BlogPosting, WebSite, BreadcrumbList, FAQPage, HowTo
- `llms.txt` and `llms-full.txt` generation
- `robots.txt` generation with AI crawler policies
- Liquid tags: `ai_json_ld`, `ai_author`, `ai_entity_link`, `ai_related_posts`, `ai_breadcrumbs`
- Entity auto-linking in post content
- Build-time validators for entity consistency, missing metadata, orphan pages
- `jekyll-seo-tag` compatibility detection
