class Upgrader::Config
  DEFAULT_HOSTING_PLATFORM = "render"

  attr_reader :env, :mode

  def initialize(env: ENV, deployer_factory: Upgrader::Deployer)
    @env = env
    @deployer_factory = deployer_factory

    # Determines the operational mode of the application based on the hosting environment.
    # :full mode indicates the application is self-hosted with capabilities for full upgrades.
    # :notifications mode indicates the application is externally hosted with only upgrade notifications supported.
    @mode = env["SELF_HOSTING_ENABLED"] == "true" ? :upgrades : :alerts
  end

  def deployer
    return @deployer_factory.for(nil) unless mode == :upgrades
    platform = env["HOSTING_PLATFORM"] || DEFAULT_HOSTING_PLATFORM
    @deployer_factory.for(platform)
  end
end
