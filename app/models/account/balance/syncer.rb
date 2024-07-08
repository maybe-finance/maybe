class Account::Balance::Syncer
  attr_reader :warnings

  def initialize(account, start_date: nil)
    @account = account
    @warnings = []
    @start_date = calculate_start_date(start_date) || Date.current
  end

  def run
  end

  private

    attr_reader :start_date, :account

    def calculate_start_date(provided_start_date)
      [ provided_start_date, account.entries.order(:date).first.try(:date) ].compact.max
    end
end
