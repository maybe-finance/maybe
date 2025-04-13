module EntryableResource
  extend ActiveSupport::Concern

  included do
    include StreamExtensions

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
      @entry.lock_saved_attributes!

      flash[:notice] = t("account.entries.create.success")

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account) }
        format.turbo_stream { stream_redirect_back_or_to account_path(@entry.account) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @entry.update(update_entry_params)
      @entry.sync_account_later
      @entry.lock_saved_attributes!
      @entry.entryable.lock_saved_attributes!

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: t("account.entries.update.success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "header_account_entry_#{@entry.id}",
              partial: "#{entryable_type.name.underscore.pluralize}/header",
              locals: { entry: @entry }
            ),
            turbo_stream.replace("account_entry_#{@entry.id}", partial: "account/entries/entry", locals: { entry: @entry })
          ]
        end
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    account = @entry.account
    @entry.destroy!
    @entry.sync_account_later

    flash[:notice] = t("account.entries.destroy.success")

    respond_to do |format|
      format.html { redirect_back_or_to account_path(account) }

      redirect_target_url = request.referer || account_path(@entry.account)
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, redirect_target_url) }
    end
  end

  private
    def entryable_type
      permitted_entryable_types = %w[Account::Transaction Account::Valuation Account::Trade]
      klass = params[:entryable_type] || "Account::#{controller_name.classify}"
      klass.constantize if permitted_entryable_types.include?(klass)
    end

    def set_entry
      @entry = Current.family.entries.find(params[:id])
    end

    def build_entry
      Current.family.entries.new(create_entry_params)
    end

    def update_entry_params
      prepared_entry_params
    end

    def create_entry_params
      prepared_entry_params.merge({
        entryable_type: entryable_type.name,
        entryable_attributes: entry_params[:entryable_attributes] || {}
      })
    end

    def prepared_entry_params
      default_params = entry_params.except(:nature)
      default_params = default_params.merge(entryable_type: entryable_type.name) if entry_params[:entryable_attributes].present?

      if entry_params[:nature].present? && entry_params[:amount].present?
        signed_amount = entry_params[:nature] == "inflow" ? -entry_params[:amount].to_d : entry_params[:amount].to_d
        default_params = default_params.merge(amount: signed_amount)
      end

      default_params
    end

    def entry_params
      params.require(:account_entry).permit(
        :account_id, :name, :enriched_name, :date, :amount, :currency, :excluded, :notes, :nature,
        entryable_attributes: self.class.permitted_entryable_attributes
      )
    end
end
