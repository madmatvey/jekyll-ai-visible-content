# Changelog

## 0.4.6 (2026-04-07)

- Fix entity auto-linking to avoid nested `<a>` tags by skipping replacements inside existing anchor blocks
- Add integration regression coverage for homepage nested-anchor prevention
- Resolve remaining RuboCop style offense in `EntityClassifier`

## 0.4.5 (2026-04-07)

- Apply safe layout fix by moving `link[rel="ai:*"]` injection into `<head>` while keeping AI instruction block before `</body>`
- Avoid appending raw `<link>` elements at the end of `<body>` to prevent theme/script edge-case rendering issues
- Keep AI resource discovery behavior unchanged for JSON/YAML/Markdown links

## 0.4.4 (2026-04-07)

- Refine AI page markdown output to exclude full Jekyll front matter and keep only AI-relevant intro metadata
- Build structured AI-readable markdown preface from `title`, `subtitle`, and `description`
- Keep body content markdown while stripping Liquid/Jekyll template directives for cleaner LLM ingestion

## 0.4.3 (2026-04-07)

- Serve `/ai/page/*.md` as raw markdown output (not HTML-rendered) by generating text-backed pages with `.md` permalinks
- Strip Liquid/Jekyll service tags (`{% ... %}`, `{{ ... }}`, comment blocks) from AI markdown content for cleaner machine-readable text
- Read markdown content from source files to avoid leaking internal Jekyll runtime objects into AI resources

## 0.4.2 (2026-04-07)

- Ensure AI link and instruction injection also works reliably on home and about pages via URL normalization/fallback lookup
- Generate page-level markdown resources under `/ai/page/<slug>.md` using real source front matter/content instead of entity summary markdown
- Improve markdown resource slug normalization and add coverage for home-page injection and page-markdown outputs

## 0.4.1 (2026-04-07)

- Add fallback entity classification for general articles (derive stable topic slug from page URL/title when explicit entities are absent)
- Ensure AI resources are generated for ordinary posts/pages so AI link injection can still occur
- Add regression test coverage for general-article fallback classification

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
