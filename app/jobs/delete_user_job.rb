class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(user_attributes)
    user = User.new(user_attributes)
    family = Family.find(user.family_id)

    if user.role == "member"
      Rails.logger.info "Is member"
      other_family_users = User.where(family_id: user.family_id).where.not(id: user.id).count

      ActiveRecord::Base.transaction do
        # this is true for our demo user but should not normally happen
        if other_family_users == 0
          if family != nil
            Rails.logger.info "about to destroy family #{family.id}"
            family.destroy
          end
        end
      end
    elsif user.role == "admin"
      Rails.logger.info "Handling accound deletion for an admin User #{user.id}"
      other_admins = User.where(family_id: user.family_id, role: "admin").where.not(id: user.id).count

      Rails.logger.info "Other admins count #{other_admins}"
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
