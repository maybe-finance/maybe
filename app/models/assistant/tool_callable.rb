module Assistant::ToolCallable
  extend ActiveSupport::Concern

  class_methods do
    def available_functions
      [
        Assistant::Function::GetBalanceSheet,
        Assistant::Function::GetIncomeStatement,
        Assistant::Function::GetExpenseCategories,
        Assistant::Function::GetAccountBalances,
        Assistant::Function::GetTransactions,
        Assistant::Function::ComparePeriods
      ]
    end
  end

  def get_function(name)
    fn = self.class.available_functions.find { |fn| fn.name == name }
    raise "Assistant does not implement function: #{name}" if fn.nil?
    fn
  end
end
