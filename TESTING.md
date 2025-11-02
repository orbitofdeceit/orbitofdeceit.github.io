# Testing

This repository uses Bats (Bash Automated Testing System) to validate the Zola site against a running local server.

## Requirements

- Zola running locally:
    - `zola serve` (defaults to http://127.0.0.1:1111)
- Bats test runner:
    - macOS: `brew install bats-core`
    - Ubuntu CI: installed via `apt-get install bats`

## Run tests locally

```bash
zola serve &   # or in another terminal
bats -r tests
```

Override the base URL if needed:

```bash
BASE_URL=http://127.0.0.1:1111 bats -r tests
```

## What is covered

- Homepage loads and has the correct title
- Post index lists posts
- Each post returns HTTP 200
- Categories index and per-category pages return HTTP 200
- Zola internal links using `@/` resolve
- Root-relative internal HTML links resolve
- Main RSS feed and per-category RSS feeds exist and have XML markers
- Static assets (favicon) load

## Pre-push hook

The `.githooks/pre-push` hook starts a local Zola server and runs `bats -r tests`. If any test fails, the push is aborted.

Enable hooks after cloning:

```bash
git config core.hooksPath .githooks
```

## CI integration

The `.github/workflows/deploy.yml` workflow runs the Bats suite in the `test` job against a live Zola server before building and deploying.
