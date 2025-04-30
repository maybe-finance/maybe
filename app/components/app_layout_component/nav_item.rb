class AppLayoutComponent::NavItem < ViewComponent::Base
  attr_reader :name, :path, :icon, :icon_custom, :active, :mobile_only

  def initialize(name:, path:, icon:, icon_custom: false, active: false, mobile_only: false)
    @name = name
    @path = path
    @icon = icon
    @icon_custom = icon_custom
    @active = active
    @mobile_only = mobile_only
  end
end
