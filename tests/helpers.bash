#!/usr/bin/env bash
# Helper functions for Bats tests

: "${BASE_URL:=http://127.0.0.1:1111}"

status_code_for() {
  local url="$1"
  curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000"
}

body_for() {
  local url="$1"
  curl -s "$url" 2>/dev/null || echo ""
}

check_url() {
  local url="$1"
  local want_desc="$2"
  local code
  code=$(status_code_for "$url")
  if [[ "$code" == "200" ]]; then
    echo "PASS: $want_desc (HTTP $code)"
    return 0
  else
    echo "FAIL: $want_desc (HTTP $code)"
    return 1
  fi
}

check_content() {
  local url="$1"
  local pattern="$2"
  local desc="$3"
  local body
  body=$(body_for "$url")
  if echo "$body" | grep -qE "$pattern"; then
    echo "PASS: $desc"
    return 0
  else
    echo "FAIL: $desc - pattern not found: $pattern"
    return 1
  fi
}

extract_html_links() {
  local url="$1"
  local content
  content=$(body_for "$url")
  echo "$content" \
    | grep -o 'href="[^"]*"' \
    | sed 's/href="//;s/"$//' \
    | grep -v '^http' \
    | grep -v '^#' \
    | grep -v '^mailto:' \
    | sort -u
}

extract_zola_links_from_source() {
  local post_file="$1"
  if [[ -f "$post_file" ]]; then
    grep -o '\[@/[^]]*\]' "$post_file" 2>/dev/null \
      | sed 's/\[@\///;s/\]$//' \
      | sed 's/\.md$/\//'
  fi
}

discover_posts() {
  local f slug
  for f in content/posts/*.md; do
    [[ $(basename "$f") == "_index.md" ]] && continue
    slug=$(basename "$f" .md)
    echo "$slug"
  done
}

fetch_categories() {
  # Returns list like /categories/<name>/
  body_for "$BASE_URL/categories/" \
    | sed 's/&#x2F;/\//g' \
    | grep -oE 'href="[^"]*categories/[^/"]*/?"' \
    | sed 's|href="||;s|"$||' \
    | sed 's|.*/categories/|/categories/|' \
    | sed 's|/*$|/|' \
    | grep -v '^/categories/$' \
    | sort -u
}
