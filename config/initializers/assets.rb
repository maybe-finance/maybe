# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << "app/components"
Rails.application.config.importmap.cache_sweepers << Rails.root.join("app/components")
