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
      delete_user
      logout
      redirect_to new_session_path, notice: t(".success")
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
    # raise StandardError.new "Unexpected error"
    if Current.user.isMember
      Rails.logger.info "Is member"
      other_family_users = User.where(family_id: Current.user.family_id).where.not(id: Current.user.id).count
      ActiveRecord::Base.transaction do
        if other_family_users == 0
          # this is true for our demo user but should not normally happen
          Current.family.destroy # this takes care of deleting all related accounts
        end
        Current.user.destroy
      end
    ## TODO: work on other edge cases involving admin and others
    ## TODO: handle errors properly if the transaction fails
    end
  end
end
