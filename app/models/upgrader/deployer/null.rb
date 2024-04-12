class Upgrader::Deployer::Null
  def deploy(upgrade)
    {
      success: true,
      message: I18n.t("upgrader.deployer.null_deployer.success_message")
    }
  end
end
