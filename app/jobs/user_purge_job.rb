class UserPurgeJob < ApplicationJob
  queue_as :low_priority

  def perform(user)
    user.purge
  end
end
