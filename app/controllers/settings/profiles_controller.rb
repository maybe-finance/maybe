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
      Rails.logger.info "DESTROYING"
      delete_user
      logout
      redirect_to new_registration_path, notice: t(".success")
    rescue ActiveRecord::RecordNotDestroyed => e
      Rails.logger.error "Error deleting account: #{e.message}"
      return redirect_to settings_profile_path, alert: t(".account_deletion_failed")
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

  def delete_user
    attributes = Current.user.attributes
    Current.user.destroy!

    DeleteUserJob.perform_later(attributes)
  end
end
