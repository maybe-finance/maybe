# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "stimulus-clipboard", to: "https://ga.jspm.io/npm:stimulus-clipboard@3.3.0/dist/stimulus-clipboard.mjs"
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.1/dist/stimulus.js"
pin "@addresszen/address-lookup", to: "https://ga.jspm.io/npm:@addresszen/address-lookup@2.0.0/dist/address-lookup.esm.js"
pin "stimulus-timeago", to: "https://ga.jspm.io/npm:stimulus-timeago@4.1.0/dist/stimulus-timeago.mjs"
pin "date-fns", to: "https://ga.jspm.io/npm:date-fns@2.29.3/esm/index.js"
