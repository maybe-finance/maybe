require 'rails_helper'

RSpec.describe BudgetCategory, type: :model do
  describe '.uncategorized' do
    let(:budget) { create(:budget, currency: 'EUR') }
    
    it 'creates a valid budget category' do
      uncategorized = described_class.uncategorized
      expect(uncategorized).to be_valid
    end

    it 'sets budgeted_spending to 0' do
      uncategorized = described_class.uncategorized
      expect(uncategorized.budgeted_spending).to eq(0)
    end

    it 'uses budget currency when budget is provided' do
      uncategorized = described_class.uncategorized(budget)
      expect(uncategorized.currency).to eq('EUR')
    end

    it 'defaults to USD when no budget is provided' do
      uncategorized = described_class.uncategorized
      expect(uncategorized.currency).to eq('USD')
    end

    it 'generates consistent UUID for uncategorized category' do
      uuid1 = described_class.uncategorized.id
      uuid2 = described_class.uncategorized.id
      expect(uuid1).to eq(uuid2)
    end
  end
end
