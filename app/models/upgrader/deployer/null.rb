class Upgrader::Deployer::Null
  def deploy(upgrade)
    # no-op
    true
  end
end
