class Upgrader::Deployer::Render
  def deploy(upgrade)
    puts "Deploying #{upgrade.type} #{upgrade.commit_sha} to Render..."
    true
  end
end
