class Onboarding
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def complete?
    settings_complete? && profile_complete?
  end

  def current_step
    return :profile if settings_complete?
    :settings
  end

  def settings_complete?
    user.family.date_format.present? && user.family.country.present?
  end

  def profile_complete?
    user.first_name.present? && user.last_name.present? && user.email.present?
  end
end
