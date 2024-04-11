class Upgrader::Deployer::Null
  def deploy(upgrade)
    {
      success: true,
      message: "No-op: null deployer initiated deploy successfully"
    }
  end
end
