module EntryableResource
  extend ActiveSupport::Concern

  included do
    layout :with_sidebar
    before_action :set_entry, only: %i[show update destroy]
  end

  class_methods do
    def permitted_entryable_attributes(*attrs)
      @permitted_entryable_attributes = attrs if attrs.any?
      @permitted_entryable_attributes ||= [ :id ]
    end
  end

  def show
  end

  def new
    account = Current.family.accounts.find_by(id: params[:account_id])

    @entry = Current.family.entries.new(
      account: account,
      currency: account ? account.currency : Current.family.currency,
      entryable: entryable_type.new
    )
  end

  def create
    @entry = build_entry

    if @entry.save
      @entry.sync_account_later

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: t("account.entries.create.success") }
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, account_path(@entry.account)) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @entry.update(prepared_entry_params)
      @entry.sync_account_later

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: t("account.entries.update.success") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "header_account_entry_#{@entry.id}",
            partial: "#{entryable_type.name.underscore.pluralize}/header",
            locals: { entry: @entry }
          )
        end
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy!
    @entry.sync_account_later
  end

  private
    def entryable_type
      klass = params[:entryable_type] || "Account::#{controller_name.classify}"
      klass.constantize
    end

    def set_entry
      @entry = Current.family.entries.find(params[:id])
    end

    def build_entry
      Current.family.entries.new(prepared_entry_params)
    end

    def prepared_entry_params
      default_params = entry_params.except(:nature)
                                   .merge(
                                     entryable_type: entryable_type.name,
                                     entryable_attributes: entry_params[:entryable_attributes] || {}
                                   )

      default_params = default_params.merge(amount: signed_amount) if signed_amount

      default_params
    end

    def signed_amount
      return nil unless entry_params[:nature].present? && entry_params[:amount].present?

      entry_params[:nature] == "inflow" ? -entry_params[:amount].to_d : entry_params[:amount].to_d
    end

    def entry_params
      params.require(:account_entry).permit(
        :account_id, :name, :date, :amount, :currency, :excluded, :notes, :nature,
        entryable_attributes: self.class.permitted_entryable_attributes
      )
    end
end
