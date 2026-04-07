[![CI](https://github.com/madmatvey/jekyll-ai-visible-content/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/madmatvey/jekyll-ai-visible-content/actions/workflows/ci.yml)

# jekyll-ai-visible-content

A Jekyll plugin gem that maximizes your site's discoverability by AI search systems (ChatGPT, Perplexity, Google AI Overviews, Claude). It generates rich JSON-LD structured data, `llms.txt`, semantic HTML helpers, and manages entity identity across your site.

## Why This Exists

AI search engines don't just crawl keywords — they build **entity graphs**. They link your name to your skills, your employer, your location, and your content. This plugin ensures your Jekyll site feeds those systems exactly the structured data they need, in the formats they understand best.

What `jekyll-seo-tag` does for Google snippets, this gem does for AI answer engines.

## Features

- **Rich JSON-LD generation**: Person, BlogPosting, WebSite, BreadcrumbList, FAQPage, HowTo schemas
- **Stable entity identity**: `@id` anchors and `sameAs` linking across all pages
- **`llms.txt` generation**: Machine-readable site summary for LLM ingestion
- **AI crawler policies**: `robots.txt` with GPTBot, PerplexityBot, ClaudeBot rules
- **Semantic Liquid tags**: `ai_json_ld`, `ai_author`, `ai_entity_link`, `ai_related_posts`, `ai_breadcrumbs`
- **Entity auto-linking**: Automatically wraps known entities in semantic markup
- **Build-time validation**: Warns about name inconsistencies, missing metadata, orphan pages
- **`jekyll-seo-tag` compatible**: Detects its presence and avoids duplicate schemas

## Installation

Add to your Jekyll site's `Gemfile`:

```ruby
gem "jekyll-ai-visible-content"
```

And to `_config.yml`:

```yaml
plugins:
  - jekyll-ai-visible-content
```

Then run:

```bash
bundle install
```

## Quick Start

Add this minimal configuration to `_config.yml`:

```yaml
ai_visible_content:
  entity:
    name: "Your Name"
    job_title: "Your Title"
    description: "One-sentence description of who you are and what you do."
    same_as:
      - https://linkedin.com/in/your-handle
      - https://github.com/your-handle
```

That's it. The plugin will automatically:
1. Inject JSON-LD into every page's `<head>`
2. Generate `/llms.txt` and `/llms-full.txt`
3. Generate `/robots.txt` allowing AI crawlers
4. Generate `/entity-map.json` for debugging
5. Validate your site's entity consistency at build time

## Full Configuration Reference

```yaml
ai_visible_content:
  enabled: true                              # Master switch

  # --- Entity Identity ---
  entity:
    type: Person                             # Person | Organization
    id_slug: "your-name"                     # Fragment for @id URI (auto-derived from name if omitted)
    name: "Your Name"
    alternate_names:                          # Other name forms (translations, etc.)
      - "Alternate Name"
    job_title: "Your Title"
    description: "Your bio."
    image: /assets/img/photo.jpg             # Relative or absolute URL
    email: you@example.com
    location:
      locality: "City"
      country: "US"                          # ISO 3166-1 alpha-2
    knows_about:                             # Skills/topics (used for entity linking too)
      - Ruby on Rails
      - PostgreSQL
    same_as:                                 # Links to authoritative profiles
      - https://linkedin.com/in/handle
      - https://github.com/handle
    author_aliases:                            # Slugs that map to the canonical name
      - your-slug                              # e.g., from _data/authors.yml keys
    works_for:
      type: Organization
      name: "Company Name"
    occupation:
      name: "Backend Engineer"
      location_country: "United States"
      skills: "Ruby, PostgreSQL, AWS"

  # --- JSON-LD Behavior ---
  json_ld:
    auto_inject: true                        # Inject into <head> via hook (no manual tag needed)
    include_website_schema: true             # WebSite + SearchAction on homepage
    include_breadcrumbs: true                # BreadcrumbList on all pages
    include_blog_posting: true               # BlogPosting on dated posts
    include_faq: true                        # FAQPage when faq: in front matter
    include_how_to: true                     # HowTo when how_to: in front matter
    article_body: excerpt                    # none | excerpt | full
    compact: false                           # Minify JSON-LD output

  # --- AI Crawler Policies ---
  crawlers:
    allow_gptbot: true
    allow_perplexitybot: true
    allow_claudebot: true
    allow_googlebot: true
    allow_bingbot: true
    custom_rules: []                         # [{user_agent: "Bot", directive: "Allow", path: "/"}]
    generate_robots_txt: true

  # --- llms.txt ---
  llms_txt:
    enabled: true
    title: null                              # Defaults to site.title
    description: null                        # Defaults to site.description
    sections: []                             # [{heading: "Section", content: "text"}]
    include_full_text: true                  # Also generate /llms-full.txt

  # --- Internal Linking ---
  linking:
    enable_entity_links: true                # Auto-link known entities in post body
    entity_definitions: {}                   # Custom: slug -> {name, url, description}
    max_links_per_entity_per_post: 1
    enable_related_posts: true
    related_posts_limit: 3

  # --- Validation ---
  validation:
    warn_name_inconsistency: true
    warn_missing_same_as: true
    warn_missing_dates: true
    warn_orphan_pages: true
    warn_missing_descriptions: true
    fail_build_on_error: false               # true = exit 1 on validation failure
    content_only: true                       # Only validate authored HTML content pages
    exclude_paths: []                        # Glob patterns to skip: ["/custom/*", "/drafts/*"]
    verbose: false                           # true = show every warning; false = grouped summary
    max_examples: 3                          # Max examples per warning group in summary mode
```

## Layout Integration

### Automatic Mode (Recommended)

With `json_ld.auto_inject: true` (the default), JSON-LD is injected into every HTML page's `<head>` automatically. No layout changes required.

### Manual Mode

Set `json_ld.auto_inject: false` and place the tag in your layout:

```html
<head>
  {% ai_json_ld %}
</head>
```

### Recommended Layout Structure

**`_layouts/default.html`**

```html
<!DOCTYPE html>
<html lang="{{ page.lang | default: site.lang | default: 'en' }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ page.title }} | {{ site.title }}</title>
  <meta name="description" content="{{ page.description | default: site.description }}">
  <link rel="canonical" href="{{ page.canonical_url | default: page.url | absolute_url }}">
</head>
<body>
  {% ai_breadcrumbs %}
  {{ content }}
  {% if page.layout == 'post' %}
    {% ai_related_posts limit:3 %}
  {% endif %}
</body>
</html>
```

**`_layouts/post.html`**

```html
---
layout: default
---
<article itemscope itemtype="https://schema.org/BlogPosting">
  <header>
    <h1 itemprop="headline">{{ page.title }}</h1>
    <time itemprop="datePublished" datetime="{{ page.date | date_to_xmlschema }}">
      {{ page.date | date: "%B %d, %Y" }}
    </time>
    {% if page.last_modified_at %}
    <time itemprop="dateModified" datetime="{{ page.last_modified_at | date_to_xmlschema }}">
      Updated: {{ page.last_modified_at | date: "%B %d, %Y" }}
    </time>
    {% endif %}
    {% ai_author %}
  </header>
  <div itemprop="articleBody">
    {{ content }}
  </div>
</article>
```

## Front Matter Reference

### Posts

```yaml
---
layout: post
title: "Optimizing PostgreSQL Queries: From 2 Seconds to 20ms"
date: 2025-01-15
last_modified_at: 2025-02-01T12:00:00+04:00
description: "A deep-dive into PostgreSQL query optimization."
image: /assets/img/posts/pg-optimization.jpg
author: Your Name
tags: [postgresql, query-optimization, performance]
categories: [engineering]
topics:                                        # Maps to schema:about
  - PostgreSQL
  - Query Optimization

# Optional: generates FAQPage JSON-LD
faq:
  - question: "How much can optimization improve?"
    answer: "We achieved a 100x improvement."

# Optional: generates HowTo JSON-LD
how_to:
  name: "How to Optimize PostgreSQL Queries"
  total_time: "PT2H"
  steps:
    - name: "Identify slow queries"
      text: "Use pg_stat_statements..."

# Optional: explicit related posts
related_slugs:
  - rails-n-plus-one-solutions
---
```

### Pages

```yaml
---
layout: page
title: "Your Name — Your Title"
permalink: /about/
description: "Bio description for AI extraction."
entity_type: Person                            # Triggers full Person JSON-LD
image: /assets/img/photo.jpg
---
```

## Liquid Tags

| Tag | Description |
|-----|-------------|
| `{% ai_json_ld %}` | Renders JSON-LD script tag for the current page |
| `{% ai_author %}` | Renders semantic author markup linking to /about/ |
| `{% ai_entity_link "Ruby on Rails" %}` | Renders a semantic link for a known entity |
| `{% ai_related_posts limit:3 %}` | Renders related posts with schema markup |
| `{% ai_breadcrumbs %}` | Renders HTML breadcrumb navigation |

## Liquid Filters

| Filter | Description |
|--------|-------------|
| `{{ "Ruby on Rails" \| ai_slugify }}` | Converts to `ruby-on-rails` |
| `{{ "Ruby on Rails" \| ai_entity_url }}` | Returns the entity's topic URL |
| `{{ "" \| ai_entity_name }}` | Returns the configured entity name |

## Naming Conventions

### Post Files

```
_posts/YYYY-MM-DD-descriptive-slug-with-keywords.md
```

- Lowercase, hyphen-separated slugs
- Include primary topic keyword in slug
- Avoid generic slugs (`post-1`, `update`, `new-thing`)

### Titles

```
[Action] [Topic]: [Specific Outcome]
```

- "Optimizing PostgreSQL Queries: From 2 Seconds to 20ms"
- "Solving N+1 Queries in Rails: A Complete Guide"
- Include entity name in page titles (especially /about/)

### Tags

```yaml
tags: [postgresql, ruby-on-rails, aws, performance]
```

Normalized, lowercase, hyphenated. Each tag can serve as a topic hub page.

## Generated Files

| File | Description |
|------|-------------|
| `/llms.txt` | Concise site summary for LLM consumption |
| `/llms-full.txt` | Full-text version with complete post bodies |
| `/robots.txt` | AI crawler allow rules + sitemap reference |
| `/entity-map.json` | Debug file showing entity mentions and cross-references |

## Build Validation

During `jekyll build`, the plugin validates your site and prints a grouped summary:

```
AI Visible Content: === Validation Report ===
AI Visible Content: 1 posts missing last_modified_at (freshness scoring disabled)
AI Visible Content:   Missing last_modified_at in _posts/2026-03-04-redis.md
AI Visible Content: 1 content pages missing description
AI Visible Content:   Missing description in _posts/2018-01-18-first-post.md
```

### What Gets Checked

| Check | Description | Config key |
|-------|-------------|------------|
| Name inconsistency | `site.author` or post `author:` differs from `entity.name` | `warn_name_inconsistency` |
| Missing sameAs | No links to LinkedIn, GitHub, etc. | `warn_missing_same_as` |
| Missing dateModified | Posts without `last_modified_at` | `warn_missing_dates` |
| Missing description | Content pages without `description` in front matter | `warn_missing_descriptions` |
| Orphan pages | Content pages with zero inbound internal links | `warn_orphan_pages` |
| Generic titles | Titles like "About" without entity name | always on |

### Content-Only Filtering

By default (`content_only: true`), validation only checks authored HTML content pages. It automatically skips:

- **Generated files**: `robots.txt`, `llms.txt`, `entity-map.json`, `sitemap.xml`, `feed.xml`
- **Asset files**: `.js`, `.css`, `.json`, `.xml`, `.map`, `.webmanifest`
- **Tag/category pages**: `/tags/*`, `/categories/*`
- **Utility pages**: `404.html`, `redirect.html`, pagination pages (`/page2/`, etc.)
- **Assets directory**: anything under `/assets/`

Set `content_only: false` to validate all pages (not recommended for most sites).

### Author Alias Resolution

Jekyll themes like Chirpy use `_data/authors.yml` to map author slugs to names. The plugin resolves author names through two mechanisms:

1. **Explicit aliases** via `entity.author_aliases`:

```yaml
ai_visible_content:
  entity:
    name: "Eugene Leontev"
    author_aliases:
      - eugene
      - nasuta
```

2. **Automatic resolution** via `_data/authors.yml`: if a post's `author:` value is a key in `_data/authors.yml` whose `name` matches `entity.name`, no warning is emitted.

### robots.txt Conflict Detection

If your site already has a `robots.txt` (as a source file or static file), the plugin skips generation and logs a warning. Either:
- Set `crawlers.generate_robots_txt: false` to silence the warning
- Remove your existing `robots.txt` to use the generated one with AI crawler rules

### Excluding Paths from Validation

Use `validation.exclude_paths` to skip specific paths:

```yaml
ai_visible_content:
  validation:
    exclude_paths:
      - "/drafts/*"
      - "/archive/*"
```

### Verbose Mode

Set `validation.verbose: true` to see every individual warning instead of grouped summaries. Useful for debugging but noisy on large sites.

### Orphan Detection Limitation

Orphan detection scans raw Markdown/HTML content for `href=` links. It cannot detect links generated by Liquid templates (e.g., `{{ post.url }}` in `{% for post in site.posts %}`). This means posts linked only through theme-generated navigation may still appear as orphans. This is a known limitation.

Set `validation.fail_build_on_error: true` to make errors break the build in CI.

## Compatibility

- Works alongside `jekyll-seo-tag` (avoids duplicate WebSite JSON-LD)
- Works alongside `jekyll-sitemap` (does not generate its own sitemap)
- Works alongside `jekyll-feed`
- Requires Jekyll 4.0+ and Ruby 3.2+

## Development

```bash
git clone https://github.com/madmatvey/jekyll-ai-visible-content.git
cd jekyll-ai-visible-content
bundle install
bundle exec rspec -f d
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
