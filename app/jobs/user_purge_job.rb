class UserPurgeJob < ApplicationJob
  queue_as :latency_low

  def perform(user)
    user.purge
  end
end
