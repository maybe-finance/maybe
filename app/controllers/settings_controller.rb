class SettingsController < ApplicationController
  before_action :authenticate_user!

  def edit
  end

  def update
    user_params_with_family = user_params
    # Ensure we're only updating the family associated with the current user
    if Current.family
      family_attributes = user_params_with_family[:family_attributes].merge({id: Current.family.id})
      user_params_with_family[:family_attributes] = family_attributes
    end

    # If the family attribute for currency is changed, we need to convert all account balances to the new currency with the ConvertCurrencyJob job
    if user_params_with_family[:family_attributes][:currency] != Current.family.currency
      ConvertCurrencyJob.perform_later(Current.family)
    end

    if Current.user.update(user_params_with_family)
      redirect_to root_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation,
                                 family_attributes: [ :name, :id, :currency ])
  end
end
