Rails.application.configure do
  Rack::MiniProfiler.config.skip_paths = [ "/design-system", "/assets", "/cable", "/manifest", "/favicon.ico", "/hotwire-livereload", "/logo-pwa.png" ]
  Rack::MiniProfiler.config.max_traces_to_show = 50
end
