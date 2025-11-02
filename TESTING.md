# Site Testing Guide

This document describes the testing infrastructure for The Paranoid Tip Zola site.

## Overview

The site uses a minimal, dependency-free testing approach using only shell scripts and `curl`. No JavaScript test frameworks or package managers required.

## Test Suite

### test-site.sh

A comprehensive Bash script that tests the rendered site against a running Zola server.

**Requirements:**
- Bash shell
- `curl` command (standard on macOS and Linux)
- A running Zola server (on port 1111 by default)

**Usage:**

```bash
# Default: tests against http://127.0.0.1:1111
./test-site.sh

# Custom URL
BASE_URL=http://localhost:8080 ./test-site.sh
```

**Tests Performed:**

1. **Site Accessibility** - Verifies the site is running and responding
2. **Homepage Tests** - Checks title, content, and post listings
3. **Individual Post Tests** - Verifies each post renders correctly
4. **Category Pages** - Tests category index and individual category pages
5. **Zola Internal Links** - Validates `@/posts/...` style links in source files
6. **HTML Link Validation** - Checks all internal links in rendered HTML
7. **RSS Feeds** - Validates main RSS feed and category-specific feeds
8. **Static Assets** - Checks favicon and other static files

**Exit Codes:**
- `0` - All tests passed
- `1` - One or more tests failed

## Automated Testing

### Pre-Push Hook

Located at `.githooks/pre-push`, this hook:
1. Starts a temporary Zola server
2. Runs the test suite
3. Aborts the push if tests fail
4. Cleans up the temporary server

**Setup:**

After cloning the repository, run:
```bash
git config core.hooksPath .githooks
```

This only needs to be done once per clone.

### GitHub Actions

The `.github/workflows/deploy.yml` workflow includes a `test` job that:
1. Checks out the code
2. Installs Zola
3. Starts Zola server
4. Runs the test suite
5. Only proceeds to build/deploy if tests pass

Tests run automatically on every push to the `master` branch.

## Understanding Test Output

The test script provides colored output:
- 🟡 **[TEST]** - Test section starting
- 🟢 **[PASS]** - Individual test passed
- 🔴 **[FAIL]** - Individual test failed

Example output:
```
[TEST] Testing individual posts...
[PASS] Post 'agile-manifesto' loads (HTTP 200)
[PASS] Post 'javascript' loads (HTTP 200)
[FAIL] Post 'missing-post' loads (HTTP 404)
```

## Adding New Tests

To add tests for new content:

1. Add post slugs to the `POSTS` array in `test-site.sh`
2. Add specific content checks using the `check_content` function
3. Test locally before pushing

Example:
```bash
POSTS=(
    "agile-manifesto"
    "your-new-post"  # Add here
)
```

## Troubleshooting

### "Site is not accessible"
- Ensure Zola is installed: `zola --version`
- Check if port 1111 is available: `lsof -i :1111`
- Try starting Zola manually: `zola serve --port 1111`

### "Broken Zola link"
- These are internal links using `@/` syntax in markdown files
- Example: `[@/posts/other-post.md]` 
- Verify the target file exists in the `content/` directory

### "Broken HTML link"
- These are rendered `<a href="...">` links in the HTML
- Check the site's navigation and post content
- Use browser dev tools to inspect the actual HTML

## Design Philosophy

This testing approach prioritizes:
- **Zero dependencies** - Only requires tools already on most systems
- **Simple maintenance** - Shell scripts are easy to understand and modify
- **Fast execution** - Tests complete in seconds
- **Clear feedback** - Colored output makes failures obvious
- **CI/CD integration** - Works seamlessly in GitHub Actions

No npm packages, no version conflicts, no security vulnerabilities from outdated dependencies.
