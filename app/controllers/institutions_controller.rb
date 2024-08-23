class InstitutionsController < ApplicationController
  before_action :set_institution, except: %i[new create]

  def new
    @institution = Institution.new
  end

  def create
    Current.family.institutions.create!(institution_params)
    redirect_to accounts_path, notice: t(".success")
  end

  def edit
  end

  def update
    @institution.update!(institution_params)
    redirect_to accounts_path, notice: t(".success")
  end

  def destroy
    @institution.destroy!
    redirect_to accounts_path, notice: t(".success")
  end

  private

    def institution_params
      params.require(:institution).permit(:name, :logo)
    end

    def set_institution
      @institution = Current.family.institutions.find(params[:id])
    end
end
