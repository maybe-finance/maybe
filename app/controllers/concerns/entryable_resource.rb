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
    if builder.create
      redirect_back_or_to account_path(@entry.account), notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if builder.update(@entry)
      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: t(".success") }
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
      "Account::#{controller_name.classify}".constantize
    end

    def set_entry
      @entry = Current.family.entries.find(params[:id])
    end

    def builder
      raise NotImplementedError, "#{self.class} must implement a builder"
    end

    def entry_params
      params.require(:account_entry).permit(
        :account_id, :name, :date, :amount, :currency, :excluded, :notes, :nature,
        *self.class.permitted_entryable_attributes
      )
    end
end
