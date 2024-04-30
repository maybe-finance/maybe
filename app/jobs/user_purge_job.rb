class UserPurgeJob < ApplicationJob
  queue_as :default

  def perform(user)
    user.purge
  end
end
