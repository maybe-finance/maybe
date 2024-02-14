# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@github/hotkey", to: "@github--hotkey.js" # @3.1.0

# To add additional D3 packages, run `/bin/importmap pin d3-<package-name>`
# For example, to add d3-selection, run `/bin/importmap pin d3-selection`
pin "d3-selection" # @3.0.0
pin "d3-scale" # @4.0.2
pin "d3-array" # @3.2.4
pin "d3-color" # @3.1.0
pin "d3-format" # @3.1.0
pin "d3-interpolate" # @3.0.1
pin "d3-time" # @3.1.0
pin "d3-time-format" # @4.1.0
pin "internmap" # @2.0.3
pin "d3-axis" # @3.0.0
pin "d3-shape" # @3.2.0
pin "d3-path" # @3.1.0

# Custom namespace for local files
pin "@maybe/tailwindcolors", to: "tailwindColors.js"
