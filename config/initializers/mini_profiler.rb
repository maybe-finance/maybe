Rails.application.configure do
  Rack::MiniProfiler.config.skip_paths = [ "/design-system" ]
  Rack::MiniProfiler.config.max_traces_to_show = 30
end
