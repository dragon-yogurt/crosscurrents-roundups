#!/bin/bash
# Regenerate the top-level index.html's weekly listing from the date directories
# present in this repo. Globs 20*-* directories, sorts newest-first, extracts
# each week's title from its index.html <title> element, and replaces the
# contents of <ul class="weeks">...</ul> in top-level index.html.
#
# Run this before each `git commit` so the index is always consistent with the
# directories present.
#
# Usage:
#   ./build-index.sh                    # rewrite index.html in place
#
# Exit codes:
#   0 on success
#   1 if the <ul class="weeks">...</ul> block can't be found in index.html
#     (e.g., template was edited and the marker was removed)

set -e
cd "$(dirname "$0")"

ENTRIES=$(
for dir in $(ls -d 20*-* 2>/dev/null | sort -r); do
    [ -f "$dir/index.html" ] || continue
    # Extract title from <title>...</title>; strip the "Heterodox Roundup: " prefix
    TITLE=$(grep -o '<title>[^<]*</title>' "$dir/index.html" | sed 's|<title>||;s|</title>||' | head -1)
    LABEL=${TITLE#Heterodox Roundup: }
    [ -z "$LABEL" ] && LABEL="Roundup for $dir"
    cat <<EOF
  <li>
    <a href="$dir/">$LABEL</a>
    <span class="date">published $dir</span>
  </li>
EOF
done
)

if [ -z "$ENTRIES" ]; then
    echo "No date directories (20*-*) found with index.html — nothing to do." >&2
    exit 0
fi

ENTRIES="$ENTRIES" python3 <<'PYEOF'
import os, re, sys
with open('index.html') as f:
    html = f.read()
entries = os.environ['ENTRIES']
new_block = f'<ul class="weeks">\n{entries}</ul>'
html_new = re.sub(r'<ul class="weeks">.*?</ul>', new_block, html, flags=re.DOTALL)
if html_new == html:
    print('FAIL: <ul class="weeks">...</ul> block not found in index.html', file=sys.stderr)
    sys.exit(1)
with open('index.html', 'w') as f:
    f.write(html_new)
n = entries.count('<li>')
print(f'index.html updated with {n} week{"s" if n != 1 else ""}')
PYEOF
