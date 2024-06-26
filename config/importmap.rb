# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/services", under: "services", to: "services"
pin "@github/hotkey", to: "@github--hotkey.js" # @3.1.0

# Custom namespace for local files
pin "@maybe/tailwindcolors", to: "tailwindColors.js"

# D3 packages
pin "d3" # @7.8.5
pin "d3-array" # @3.2.4
pin "d3-axis" # @3.0.0
pin "d3-brush" # @3.0.0
pin "d3-chord" # @3.0.1
pin "d3-color" # @3.1.0
pin "d3-contour" # @4.0.2
pin "d3-delaunay" # @6.0.4
pin "d3-dispatch" # @3.0.1
pin "d3-drag" # @3.0.0
pin "d3-dsv" # @3.0.1
pin "d3-ease" # @3.0.1
pin "d3-fetch" # @3.0.1
pin "d3-force" # @3.0.0
pin "d3-format" # @3.1.0
pin "d3-geo" # @3.1.0
pin "d3-hierarchy" # @3.1.2
pin "d3-interpolate" # @3.0.1
pin "d3-path" # @3.1.0
pin "d3-polygon" # @3.0.1
pin "d3-quadtree" # @3.0.1
pin "d3-random" # @3.0.1
pin "d3-scale" # @4.0.2
pin "d3-scale-chromatic" # @3.0.0
pin "d3-selection" # @3.0.0
pin "d3-shape" # @3.2.0
pin "d3-time" # @3.1.0
pin "d3-time-format" # @4.1.0
pin "d3-timer" # @3.0.1
pin "d3-transition" # @3.0.1
pin "d3-zoom" # @3.0.0
pin "delaunator" # @5.0.1
pin "internmap" # @2.0.3
pin "robust-predicates" # @3.0.2
pin "dropzone" # @6.0.0
pin "just-extend" # @5.1.1
pin "@rails/activestorage", to: "activestorage.esm.js"
