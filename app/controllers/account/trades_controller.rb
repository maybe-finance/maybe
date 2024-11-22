class Account::TradesController < ApplicationController
  include EntryableResource

  permitted_entryable_attributes :id, :qty, :ticker, :price

  def create
    @builder = Account::EntryBuilder.new(entry_params)

    if entry = @builder.save
      entry.sync_account_later
      redirect_to @entry.account, notice: t(".success")
    else
      flash[:alert] = t(".failure")
      redirect_back_or_to @entry.account
    end
  end

  def securities
    query = params[:q]
    return render json: [] if query.blank? || query.length < 2 || query.length > 100

    @securities = Security::SynthComboboxOption.find_in_synth(query)
  end

  private
    def entry_params
      base_entry_params.tap do |base_params|
        trade_params = base_params[:entryable_attributes]
        nature = base_params[:nature]

        if trade_params.present? && trade_params[:price].present? && trade_params[:qty].present?
          if nature.present? && nature == "sell"
            trade_params[:qty] = trade_params[:qty].to_d * -1
          end

          base_params[:amount] = trade_params[:price].to_d * trade_params[:qty].to_d
        end

        base_params[:entryable_attributes] = trade_params if trade_params.present?
        base_params.delete(:nature)
      end
    end
end
