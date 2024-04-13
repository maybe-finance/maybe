class Upgrader::Deployer
  def self.for(platform)
    case platform
    when nil, "localhost"
      Upgrader::Deployer::Null.new
    when "render"
      Upgrader::Deployer::Render.new
    else
      raise "Unknown platform: #{platform}"
    end
  end
end
