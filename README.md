# orbitofdeceit.github.io

This repository is a GitHub Pages site built with [Zola](https://www.getzola.org/), a fast static site generator written in Rust.

This README documents how to build and serve the site locally, the CI deployment pipeline, and the site structure.

## Quick start (recommended)

### Requirements
- macOS, Linux, or Windows
- Zola 0.18.0+ (installation instructions below)

### Install Zola

**macOS (Homebrew)**
```bash
brew install zola
```

**Linux**
```bash
# Download and install from GitHub releases
ZOLA_VERSION="0.18.0"
wget -q -O zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf zola.tar.gz
sudo mv zola /usr/local/bin/
```

**Windows**
```powershell
# Using Scoop
scoop install zola

# Or download from https://github.com/getzola/zola/releases
```

### Local development

```bash
# Build the site
zola build
# Output is in public/

# Serve with live reload
zola serve
# Site available at http://127.0.0.1:1111
```

## Site structure

```
.
├── config.toml          # Site configuration
├── content/             # All content files
│   ├── _index.md        # Homepage content
│   ├── posts/           # Blog posts
│   │   ├── _index.md    # Posts section config
│   │   └── *.md         # Individual posts
│   └── pages/           # Static pages
│       ├── _index.md    # Pages section config
│       └── about.md     # About page
├── templates/           # Tera templates
│   ├── base.html        # Base template
│   ├── index.html       # Homepage template
│   ├── page.html        # Page template
│   └── ...
└── static/              # Static assets (copied as-is)
    ├── css/             # Stylesheets
    └── images/          # Images (logo, etc.)
```

## CI and automated deployment

- `.github/workflows/deploy.yml` — builds the site with Zola on push to `master` and deploys to GitHub Pages automatically
- The workflow:
  1. Installs Zola 0.18.0
  2. Runs `zola build`
  3. Checks artifact size (must be < 10GB)
  4. Uploads and deploys to GitHub Pages

The site is automatically deployed to **https://orbitofdeceit.github.io** on every push to `master`.

## Content management

### Creating a new post

1. Create a new Markdown file in `content/posts/`:
```bash
zola post create posts/my-new-post.md
```

2. Add front matter (TOML format):
```toml
+++
title = "My New Post"
date = 2025-10-31
[taxonomies]
categories = ["Other"]
+++

Your content here...
```

3. Build and preview:
```bash
zola serve
```

### Front matter fields

Required:
- `title` — Post title
- `date` — Publication date (YYYY-MM-DD format)

Optional:
- `description` — Meta description
- `[taxonomies]` — Categories and tags
- `template` — Override default template

## Features

- ✅ RSS feed at `/rss.xml`
- ✅ Sitemap at `/sitemap.xml`
- ✅ Category pages with individual RSS feeds
- ✅ Pagination (10 posts per page)
- ✅ Responsive design with circular logo
- ✅ Fast build times (~30ms)

## Migration notes

This site was migrated from Jekyll to Zola in October 2025. All 34 blog posts, templates, and assets were successfully ported. Jekyll-specific files have been removed.

## Troubleshooting

**Build errors**
```bash
# Check for path collisions
zola check

# Verbose build output
zola build --verbose
```

**Port already in use**
```bash
# Use a different port
zola serve --port 8080
```

**GitHub Pages not updating**
- Check the Actions tab for workflow run status
- Ensure Settings → Pages → Source is set to "GitHub Actions"

## Links

- [Zola documentation](https://www.getzola.org/documentation/)
- [Tera template documentation](https://tera.netlify.app/docs/)
- [Live site](https://orbitofdeceit.github.io)
