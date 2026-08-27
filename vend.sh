#!/usr/bin/env bash
# Copy the kit into every example that carries it, and say what moved.
#
# Copies rather than a package, deliberately: an example has to be a repository
# a person can read top to bottom and deploy in one click, and a shared
# dependency would make sixteen apps un-runnable the day this one moved. The
# cost of that choice is this script and the check under it.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"

css="$here/launchpad-kit.css"
js="$here/launchpad-kit.js"
ico="$here/favicon.svg"

# repo:dir:what  — what is any of  css js ico
targets="
launchpad-example-fastapi-reconcile:static:css js ico
launchpad-example-flask-hello:static:css js ico
launchpad-example-marimo-runway:static:css ico
launchpad-example-mcp-server:static:css ico
launchpad-example-node-api:public:css js ico
launchpad-example-orders-viewer:static:css js ico
launchpad-example-plumber-stats:www:css js ico
launchpad-example-python-report:static:css js ico
launchpad-example-quarto-service-review:static:css ico
launchpad-example-rmarkdown-quality:static:css
launchpad-example-service-catalog:assets:css js ico
launchpad-example-shiny-abtest:www:css ico
launchpad-example-streamlit-explorer:static:css
launchpad-example-support-review:static:css
launchpad-example-nextjs-dashboard:app:css
"

while IFS=: read -r repo dir what; do
  [ -z "$repo" ] && continue
  dest="$root/$repo/$dir"
  [ -d "$dest" ] || { echo "missing $dest"; exit 1; }
  for w in $what; do
    case "$w" in
      css) cp "$css" "$dest/launchpad-kit.css" ;;
      js)  cp "$js"  "$dest/launchpad-kit.js" ;;
      ico) cp "$ico" "$dest/favicon.svg" ;;
    esac
  done
  echo "vended -> $repo/$dir ($what)"
done <<< "$targets"

# Two that keep the kit somewhere the loop cannot express.
cp "$js"  "$root/launchpad-example-nextjs-dashboard/public/launchpad-kit.js"
cp "$ico" "$root/launchpad-example-nextjs-dashboard/public/favicon.svg"
echo "vended -> launchpad-example-nextjs-dashboard/public (js ico)"

# Stockroom's stylesheet is the kit followed by its own layer, so it is rebuilt
# rather than copied. The layer is everything after the marker line.
stock="$root/launchpad-example-stockroom/static/app.css"
marker="   Stockroom — what this app adds to the house style."
if grep -qF "$marker" "$stock"; then
  awk -v m="$marker" 'index($0,m){found=1} found' "$stock" > /tmp/lp-stock-layer.$$
  { cat "$css"; echo; echo "/* ═══════════════════════════════════════════════════════════════════════════"; cat /tmp/lp-stock-layer.$$; } > "$stock"
  rm -f /tmp/lp-stock-layer.$$
  cp "$ico" "$root/launchpad-example-stockroom/static/favicon.svg"
  echo "rebuilt -> launchpad-example-stockroom/static/app.css (kit + layer)"
fi
