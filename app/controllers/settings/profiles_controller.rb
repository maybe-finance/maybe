class Settings::ProfilesController < ApplicationController
  def show
  end

  def update
    user_params_with_family = user_params

    if Current.family && user_params_with_family[:family_attributes]
      family_attributes = user_params_with_family[:family_attributes].merge({ id: Current.family.id })
      user_params_with_family[:family_attributes] = family_attributes
    end

    if Current.user.update(user_params_with_family)
      redirect_to settings_profile_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      if Current.user.admin?
        other_admins_count = Current.family.admins.where.not(id: Current.user.id).count
        members_count = Current.family.members.count

        if other_admins_count === 0 && members_count > 0
          return redirect_to settings_profile_path, alert: t(".cannot_delete_admin_account_warning")
        end
      end
      mark_user_for_deletion_and_logout
      redirect_to new_registration_path, notice: t(".success")
    rescue StandardError => e
      Rails.logger.error "An unexpected error occurred: #{e.message}"
      redirect_to settings_profile_path, alert: t(".account_deletion_failed")
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name,
                                 family_attributes: [ :name, :id ])
  end

  def mark_user_for_deletion_and_logout
    Current.user.update!(marked_for_deletion: true)
    DeleteUserJob.perform_later(Current.user)
    logout
  end
end
