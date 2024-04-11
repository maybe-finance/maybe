class Upgrader::Config
  DEFAULT_MODE = :alerts

  attr_reader :env, :options

  def initialize(options, env: ENV)
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

  def mode
    options[:mode] || DEFAULT_MODE
  end
end
