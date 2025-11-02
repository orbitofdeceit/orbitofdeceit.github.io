#!/usr/bin/env bats

load_helpers() {
  # Source helpers without requiring bats-support
  source "$(dirname "$BATS_TEST_FILENAME")/helpers.bash"
}

setup_file() {
  load_helpers
  # Quick availability check
  if ! curl -s -f "$BASE_URL" >/dev/null 2>&1; then
    echo "Site not accessible at $BASE_URL. Ensure 'zola serve' is running." >&2
    # Let first test report clearly instead of aborting here
  fi
}

@test "site is accessible" {
  load_helpers
  run curl -s -f "$BASE_URL"
  [ "$status" -eq 0 ]
}

@test "homepage loads and has correct title" {
  load_helpers
  run check_url "$BASE_URL" "Homepage loads"
  [ "$status" -eq 0 ]
  run check_content "$BASE_URL" "<title>The Paranoid Tip</title>" "Homepage has correct title"
  [ "$status" -eq 0 ]
}

@test "homepage shows posts" {
  load_helpers
  run check_content "$BASE_URL" "Agile Manifesto|Create Sub-Task" "Homepage shows posts"
  [ "$status" -eq 0 ]
}

@test "each post loads (HTTP 200)" {
  load_helpers
  local posts
  posts=( $(discover_posts) )
  echo "Found ${#posts[@]} posts"
  for p in "${posts[@]}"; do
    run check_url "$BASE_URL/posts/$p/" "Post '$p' loads"
    if [[ "$status" -ne 0 ]]; then
      echo "Post failed: $p"
      return 1
    fi
  done
}

@test "categories index loads and lists categories" {
  load_helpers
  run check_url "$BASE_URL/categories/" "Categories index loads"
  [ "$status" -eq 0 ]
  run check_content "$BASE_URL/categories/" "haiku|Categories" "Categories index shows categories"
  [ "$status" -eq 0 ]
}

@test "each category page loads" {
  load_helpers
  local cats
  # macOS Bash 3.2 lacks mapfile; use command substitution
  # shellcheck disable=SC2207
  cats=( $(fetch_categories) )
  if [[ ${#cats[@]} -eq 0 ]]; then
    echo "No categories found"
    return 1
  fi
  for cat_url in "${cats[@]}"; do
    run check_url "$BASE_URL${cat_url}" "Category '$(basename "$cat_url")' page loads"
    if [[ "$status" -ne 0 ]]; then
      return 1
    fi
  done
}

@test "Zola internal links (@/) referenced in posts resolve" {
  load_helpers
  local posts=()
  # shellcheck disable=SC2207
  posts=( $(discover_posts) )
  for p in "${posts[@]}"; do
    local pf="content/posts/${p}.md"
    local links
    # shellcheck disable=SC2207
    links=( $(extract_zola_links_from_source "$pf") )
    [[ ${#links[@]} -eq 0 ]] && continue
    for l in "${links[@]}"; do
      local url="$BASE_URL/$l"
      local code
      code=$(status_code_for "$url")
      if [[ "$code" != "200" ]]; then
        echo "Broken Zola link in '$p': @/$l (HTTP $code)"
        return 1
      fi
    done
  done
}

@test "internal HTML links in posts resolve (root-relative)" {
  load_helpers
  local posts=()
  # shellcheck disable=SC2207
  posts=( $(discover_posts) )
  for p in "${posts[@]}"; do
    local post_url="$BASE_URL/posts/$p/"
    local links=()
    # shellcheck disable=SC2207
    links=( $(extract_html_links "$post_url") )
    for l in "${links[@]}"; do
      [[ "$l" =~ ^/ ]] || continue
      local url="$BASE_URL$l"
      local code
      code=$(status_code_for "$url")
      if [[ "$code" != "200" ]]; then
        echo "Broken HTML link in '$p': $l (HTTP $code)"
        return 1
      fi
    done
  done
}

@test "main RSS feed exists and has XML markers" {
  load_helpers
  run check_url "$BASE_URL/rss.xml" "RSS feed exists"
  [ "$status" -eq 0 ]
  run check_content "$BASE_URL/rss.xml" "<rss|<\?xml" "RSS feed has valid XML structure"
  [ "$status" -eq 0 ]
}

@test "favicon loads" {
  load_helpers
  run check_url "$BASE_URL/favicon.ico" "Favicon loads"
  [ "$status" -eq 0 ]
}

@test "each category has RSS feed" {
  load_helpers
  local cats
  # shellcheck disable=SC2207
  cats=( $(fetch_categories) )
  for cat_url in "${cats[@]}"; do
    local cname
    cname=$(echo "$cat_url" | sed 's|/categories/||;s|/$||')
    run check_url "$BASE_URL/categories/${cname}/rss.xml" "Category '$cname' RSS feed"
    if [[ "$status" -ne 0 ]]; then
      return 1
    fi
  done
}
