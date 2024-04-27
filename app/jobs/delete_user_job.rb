class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(user)
    family = Family.find(user.family_id)

    if user.member?
      user.destroy
    elsif user.admin?
      other_admins = User.family.admins.where.not(id: user.id).count

      if other_admins == 0
        User.family.destroy # this destroys related users and accounts
      else
        user.destroy
      end
    end
  end
end
