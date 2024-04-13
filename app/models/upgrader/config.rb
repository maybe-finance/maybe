class Upgrader::Config
  attr_reader :env, :options

  def initialize(options = {}, env: ENV)
    @env = env
    @options = options
  end

  def deployer
    factory = Upgrader::Deployer
    factory.for(hosting_platform)
  end

  def hosting_platform
    options[:hosting_platform] || env["HOSTING_PLATFORM"]
  end
end
