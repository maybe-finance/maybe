class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(user_attributes)
    user = User.new(user_attributes)
    family = Family.find(user.family_id)

    puts user_attributes

    if user.role == "member"
      other_family_users = User.where(family_id: user.family_id).where.not(id: user.id).count

      ActiveRecord::Base.transaction do
        # this is true for our demo user but should not normally happen
        if other_family_users == 0
          if family != nil
            family.destroy
          end
        end
      end
    elsif user.role == "admin"
      other_admins = User.where(family_id: user.family_id, role: "admin").where.not(id: user.id).count

      if other_admins == 0
        ActiveRecord::Base.transaction do
          
          if family != nil
            family.destroy
          end
          # since other users are now invalid because of the orphaned family -> delete users as well
          users = User.where(family_id: user.family_id)
          users.destroy_all
        end
      end
    end
  end
end
