# AI Coding Agent Instructions

## Project Overview

This is a GitHub Pages blog built with **Zola 0.21.0** (Rust-based static site generator). The site is "The Paranoid Tip" - a satirical tech commentary blog, primarily haiku-style humor pieces.

**Key Architecture:**
- Zola
- Tera templating engine (similar to Jinja2)
- Zero-dependency testing with bash + curl
- Automated CI/CD via GitHub Actions
- Live at: https://orbitofdeceit.github.io

## Critical Workflows

### Development Cycle
```bash
# Start local server with live reload
zola serve
# Site runs at http://127.0.0.1:1111

# Build for production
zola build  # Output: public/

# Run test suite (requires running server)
./test-site.sh
```

### Pre-Push Requirements
Git hooks **must** be enabled after cloning:
```bash
git config core.hooksPath .githooks
```

The `.githooks/pre-push` hook enforces:
1. **Version parity check** - local Zola version must match `.github/workflows/deploy.yml`
2. **Full test suite** - all tests must pass before pushing
3. Aborts push on any failure

**If you update Zola version locally**, you MUST update:
- `.github/workflows/deploy.yml` (two places: `test` and `build` jobs)
- `README.md` installation instructions
- `TESTING.md` references

### Testing Infrastructure

The `test-site.sh` script validates:
- All 34+ posts render correctly (`/posts/<slug>/`)
- Category pages and RSS feeds (`/categories/<name>/`, `/categories/<name>/rss.xml`)
- Zola internal links using `@/` syntax (e.g., `[@/posts/other-post.md]`)
- HTML link integrity in rendered output
- Static assets (favicon, CSS)

**Run tests before any commit** - they execute in <10 seconds.

## Content Structure

### Creating Posts

Post files live in `content/posts/<slug>.md` with TOML frontmatter:

```toml
+++
date = 2025-11-02
title = "Post Title"
taxonomies.categories = ['haiku']  # or ['other']
+++

Post content here...
```

**Critical conventions:**
- Date format: `YYYY-MM-DD` (no time component)
- Categories: Only `haiku` or `other` (site has no tags)
- Slug: Derived from filename (e.g., `my-post.md` → `/posts/my-post/`)

### Internal Links

Use Zola's `@/` syntax for cross-post references:
```markdown
See ['Other Post'](@/posts/other-post.md)
```

**Never use relative paths** like `../other-post/` - Zola won't resolve them.

### Section Structure

```
content/
  _index.md         # Homepage (lists all posts)
  posts/
    _index.md       # Posts section config
    *.md            # Individual posts
  pages/
    _index.md       # Pages section config
    about.md        # Static page
```

## Template System

**Tera templates** in `templates/`:
- `base.html` - Master layout with header/footer
- `index.html` - Homepage post listing
- `page.html` - Individual post rendering
- `taxonomy_list.html` - Category index
- `taxonomy_single.html` - Single category page

**Template inheritance:**
```html
{% extends "base.html" %}
{% block content %}
  <!-- Your content -->
{% endblock %}
```

**Common Tera filters:**
- `{{ page.date | date(format="%b %-d, %Y") }}` - Format dates
- `{{ page.permalink }}` - Get full URL
- `{{ config.title }}` - Access config.toml values

## Configuration

`config.toml` controls:
- `base_url` - Must match GitHub Pages URL
- `taxonomies` - Only `categories` taxonomy with RSS enabled
- `generate_feeds` - Creates `/rss.xml` + per-category feeds
- `author` and `extra.github_username` - Used in templates

**Do not add new taxonomies** without updating templates and tests.

## Deployment Pipeline

`.github/workflows/deploy.yml` has three jobs:

1. **test** - Runs full test suite against live server
2. **build** - Builds site, checks <10GB artifact limit
3. **deploy** - Uploads to GitHub Pages

**Deployment triggers:**
- Push to `master` branch
- Manual workflow dispatch

The workflow uses `ZOLA_VERSION="0.21.0"` - keep in sync with local installations.

## Static Assets

`static/` directory contents are copied verbatim to `public/`:
- `css/main.css` - Custom styles (no preprocessor)
- `images/` - Site images
- `favicon.ico` - Site icon

**Editing CSS:**
- Edit `static/css/main.css` directly
- No build step required
- Changes apply immediately with `zola serve`

## Common Pitfalls

1. **Broken internal links** - Always use `@/posts/<slug>.md` syntax, not relative paths
2. **Test failures ignored** - Hook must be enabled: `git config core.hooksPath .githooks`
3. **Version mismatches** - Pre-push hook will abort if local/workflow Zola versions differ
4. **Missing frontmatter** - Posts without `date` won't sort correctly
5. **Invalid category** - Only `haiku` and `other` exist; new categories need template updates

## File Naming Conventions

- Post files: `kebab-case.md` (e.g., `agile-manifesto.md`)
- Templates: `snake_case.html` for taxonomies, otherwise lowercase
- Static assets: lowercase with hyphens

## Quick Reference

**Zola commands:**
- `zola check` - Validate content without building
- `zola build --drafts` - Include draft posts
- `zola serve --port 8080` - Use alternate port

**Key files:**
- `config.toml` - Site configuration
- `test-site.sh` - Test suite
- `.githooks/pre-push` - Pre-push validation
- `.github/workflows/deploy.yml` - CI/CD pipeline

**URLs to test:**
- http://127.0.0.1:1111 - Homepage
- http://127.0.0.1:1111/posts/ - Post index
- http://127.0.0.1:1111/categories/ - Category index
- http://127.0.0.1:1111/rss.xml - Main RSS feed
