class AppLayoutComponent < ViewComponent::Base
  renders_many :nav_items, NavItem
  renders_one :breadcrumbs

  # Desktop slots
  renders_one :left_sidebar
  renders_one :right_sidebar
  renders_one :desktop_user_menu

  # Mobile slots
  renders_one :mobile_sidebar
  renders_one :mobile_user_menu

  def initialize(user:)
    @user = user
  end

  def show_left?
    user.show_sidebar?
  end

  def show_right?
    user.show_ai_sidebar?
  end

  def user_id
    user.id
  end

  def left_sidebar_classes
    "w-[320px]"
  end

  def right_sidebar_classes
    "w-[400px]"
  end

  private
    attr_reader :user
end
