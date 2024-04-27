class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(user)
    if user.member?
      user.destroy
    elsif user.admin?
      other_admins = user.family.admins.where.not(id: user.id).count

      if other_admins == 0
        user.family.destroy # this destroys related users and accounts
      else
        user.destroy
      end
    end
  end
end
