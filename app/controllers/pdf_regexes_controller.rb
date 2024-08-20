class PdfRegexesController < ApplicationController
  layout :with_sidebar

  before_action :verify_pdf_imports_enabled
  before_action :set_pdf_regex, only: %i[edit update]

  def index
    @pdf_regexes = Current.family.pdf_regexes.all
  end

  def new
    @pdf_regex = Current.family.pdf_regexes.new
  end

  def create
    Current.family.pdf_regexes.create!(pdf_regex_params)
    redirect_to pdf_regexes_path, notice: t(".created")
  end

  def edit
  end

  def update
    @pdf_regex.update!(pdf_regex_params)
    redirect_to pdf_regexes_path, notice: t(".updated")
  end

  def destroy
    # TODO: cant use @pdf_regex, why Current.user is nil?
    PdfRegex.find(params[:id]).destroy!
    redirect_to pdf_regexes_path, notice: t(".success")
  end

  private

    def set_pdf_regex
      @pdf_regex = Current.family.pdf_regexes.find(params[:id])
    end

    def pdf_regex_params
      params.require(:pdf_regex).permit(
        :name,
        :transaction_line_regex_str,
        :metadata_regex_str,
        :pdf_transaction_date_format,
        :pdf_range_date_format,
      )
    end

    def verify_pdf_imports_enabled
      head :not_found unless Rails.application.config.x.maybe.pdf_imports_enabled
    end
end
