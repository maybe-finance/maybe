class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(user)
    user.purge_data
  end
end
