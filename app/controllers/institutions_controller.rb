class InstitutionsController < ApplicationController
  before_action :set_institution, except: %i[new create]

  SUCCESS = ".success".freeze

  def new
    @institution = Institution.new
  end

  def create
    Current.family.institutions.create!(institution_params)
    redirect_to accounts_path, notice: t(SUCCESS)
  end

  def edit
  end

  def update
    @institution.update!(institution_params)
    redirect_to accounts_path, notice: t(SUCCESS)
  end

  def destroy
    @institution.destroy!
    redirect_to accounts_path, notice: t(SUCCESS)
  end

  def sync
    @institution.sync
    redirect_back_or_to accounts_path, notice: t(SUCCESS)
  end

  private

    def institution_params
      params.require(:institution).permit(:name, :logo)
    end

    def set_institution
      @institution = Current.family.institutions.find(params[:id])
    end
end
