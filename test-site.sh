#!/bin/bash
set -e

BASE_URL="${BASE_URL:-http://127.0.0.1:1111}"
FAILED_TESTS=0
PASSED_TESTS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

check_url() {
    local url="$1"
    local description="$2"
    local status_code
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "200" ]; then
        log_pass "$description (HTTP $status_code)"
        return 0
    else
        log_fail "$description (HTTP $status_code)"
        return 1
    fi
}

check_content() {
    local url="$1"
    local pattern="$2"
    local description="$3"
    local content
    
    content=$(curl -s "$url" 2>/dev/null || echo "")
    
    if echo "$content" | grep -q "$pattern"; then
        log_pass "$description"
        return 0
    else
        log_fail "$description - pattern not found: $pattern"
        return 1
    fi
}

extract_html_links() {
    local url="$1"
    local content
    
    content=$(curl -s "$url" 2>/dev/null || echo "")
    echo "$content" | grep -o 'href="[^"]*"' | sed 's/href="//;s/"$//' | grep -v '^http' | grep -v '^#' | grep -v '^mailto:' | sort -u
}

extract_zola_links_from_source() {
    local post_file="$1"
    
    if [ -f "$post_file" ]; then
        grep -o '\[@/[^]]*\]' "$post_file" 2>/dev/null | sed 's/\[@\///;s/\]$//' | sed 's/\.md$/\//' || echo ""
    fi
}

echo "========================================"
echo "Testing Zola Site: $BASE_URL"
echo "========================================"
echo

log_test "Checking if site is accessible..."
if ! curl -s -f "$BASE_URL" > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Site is not accessible at $BASE_URL${NC}"
    echo "Make sure 'zola serve' is running before running tests."
    exit 1
fi
log_pass "Site is accessible"
echo

log_test "Testing homepage..."
check_url "$BASE_URL" "Homepage loads"
check_content "$BASE_URL" "<title>The Paranoid Tip</title>" "Homepage has correct title"
echo

log_test "Testing post listing on homepage..."
check_content "$BASE_URL" "Agile Manifesto\|Create Sub-Task" "Homepage shows posts"
echo

log_test "Testing individual posts..."
POSTS=(
    "agile-manifesto"
    "javascript"
    "software"
    "heritage-software"
    "management-framework"
    "gpt-2"
    "qvd"
)

for post in "${POSTS[@]}"; do
    check_url "$BASE_URL/posts/$post/" "Post '$post' loads"
done
echo

log_test "Testing category pages..."
check_url "$BASE_URL/categories/" "Categories index loads"
check_content "$BASE_URL/categories/" "haiku\|Categories" "Categories index shows categories"

CATEGORIES=$(curl -s "$BASE_URL/categories/" 2>/dev/null | sed 's/&#x2F;/\//g' | grep -oE 'href="[^"]*categories/[^/"]*/?"' | sed 's|href="||;s|"$||' | sed 's|.*/categories/|/categories/|' | sed 's|/*$|/|' | grep -v '^/categories/$' | sort -u)

if [ -z "$CATEGORIES" ]; then
    log_fail "No categories found on categories page"
else
    log_pass "Found categories on categories page"
    
    for cat_url in $CATEGORIES; do
        full_url="${BASE_URL}${cat_url}"
        cat_name=$(echo "$cat_url" | sed 's|/categories/||;s|/$||')
        check_url "$full_url" "Category '$cat_name' page loads"
    done
fi
echo

log_test "Testing Zola internal links (@/ syntax)..."
ZOLA_LINK_ERRORS=0

for post in "${POSTS[@]}"; do
    post_file="content/posts/${post}.md"
    
    if [ ! -f "$post_file" ]; then
        continue
    fi
    
    zola_links=$(extract_zola_links_from_source "$post_file")
    
    if [ -z "$zola_links" ]; then
        continue
    fi
    
    for link in $zola_links; do
        full_link="${BASE_URL}/${link}"
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$full_link" 2>/dev/null || echo "000")
        
        if [ "$status_code" = "200" ]; then
            log_pass "Zola link in '$post': @/$link"
        else
            log_fail "Broken Zola link in '$post': @/$link (HTTP $status_code)"
            ZOLA_LINK_ERRORS=$((ZOLA_LINK_ERRORS + 1))
        fi
    done
done

if [ $ZOLA_LINK_ERRORS -eq 0 ]; then
    log_pass "All Zola internal links (@/) are valid"
fi
echo

log_test "Testing HTML links in rendered posts..."
HTML_LINK_ERRORS=0

for post in "${POSTS[@]}"; do
    post_url="$BASE_URL/posts/$post/"
    links=$(extract_html_links "$post_url")
    
    if [ -z "$links" ]; then
        continue
    fi
    
    for link in $links; do
        if [[ "$link" =~ ^/ ]]; then
            full_link="${BASE_URL}${link}"
            status_code=$(curl -s -o /dev/null -w "%{http_code}" "$full_link" 2>/dev/null || echo "000")
            
            if [ "$status_code" != "200" ]; then
                log_fail "Broken HTML link in '$post': $link (HTTP $status_code)"
                HTML_LINK_ERRORS=$((HTML_LINK_ERRORS + 1))
            fi
        fi
    done
done

if [ $HTML_LINK_ERRORS -eq 0 ]; then
    log_pass "All internal HTML links are valid"
fi
echo

log_test "Testing RSS feed..."
check_url "$BASE_URL/rss.xml" "RSS feed exists"
check_content "$BASE_URL/rss.xml" "<rss\|<?xml" "RSS feed has valid XML structure"
echo

log_test "Testing static assets..."
check_url "$BASE_URL/favicon.ico" "Favicon loads"
echo

log_test "Testing category RSS feeds..."
if [ -n "$CATEGORIES" ]; then
    for cat_url in $CATEGORIES; do
        cat_name=$(echo "$cat_url" | sed 's|/categories/||;s|/$||')
        rss_url="${BASE_URL}/categories/${cat_name}/rss.xml"
        check_url "$rss_url" "Category '$cat_name' RSS feed"
    done
fi
echo

echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo

if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
