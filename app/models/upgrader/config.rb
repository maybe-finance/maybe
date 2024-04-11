class Upgrader::Config
  attr_reader :env, :options

  def initialize(options = {}, env: ENV)
    @env = env
    @options = options
  end

  def deployer
    factory = options[:deployer_factory] || Upgrader::Deployer
    factory.for(hosting_platform)
  end

  def hosting_platform
    options[:hosting_platform] || env["HOSTING_PLATFORM"]
  end

  # Upgrader Mode:
  # - "disabled": (default) No upgrades or upgrade alerts enabled (this is usually the best setting for local development)
  # - "alerts_only": App users cannot upgrade the running app, but will see alerts when a new version is pushed to production
  # - "enabled": App users can upgrade the running app to the latest version (best for self-hosting)
  def mode
    mode_value = (options[:mode] || ENV["UPGRADES_MODE"] || :disabled).to_sym
    unless [ :disabled, :alerts_only, :enabled ].include?(mode_value)
      raise ArgumentError, "Invalid mode: #{mode_value}"
    end
    mode_value
  end
end
