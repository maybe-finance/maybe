Rails.application.configure do
  Rack::MiniProfiler.config.skip_paths = [ "/design-system" ]
end
