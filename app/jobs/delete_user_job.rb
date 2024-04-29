class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(user)
    ActiveRecord::Base.transaction do
      if user.member?
        user.destroy
      elsif user.admin?
        other_admins = user.family.admins.where.not(id: user.id).count

        if other_admins == 0
          if user.family.members.count == 0
            user.family.destroy
          end
        else
          user.destroy
        end
      end
    end
  rescue => e
    Rails.logger.error "An error occurred during DeleteUserJob: #{e.message} for the user #{user.id}"
    raise e #just propagating
  end
end
