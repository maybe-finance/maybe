require 'rails_helper'

RSpec.describe Transfer, type: :model do
  let(:family) { create(:family) }
  let(:from_account) { create(:account, family: family) }
  let(:to_account) { create(:account, family: family) }
  
  describe 'concurrent operations' do
    let!(:inflow_transaction) { create(:account_transaction) }
    let!(:outflow_transaction) { create(:account_transaction) }

    it 'handles concurrent transfer creation without deadlocks' do
      threads = []
      expect do
        2.times do
          threads << Thread.new do
            Transfer.create_transfer!(
              inflow_transaction_id: inflow_transaction.id,
              outflow_transaction_id: outflow_transaction.id
            )
          end
        end
        threads.each(&:join)
      end.not_to raise_error
      
      expect(Transfer.count).to eq(1)
    end

    context 'when rejecting transfers concurrently' do
      let!(:transfer) { create(:transfer, inflow_transaction: inflow_transaction, outflow_transaction: outflow_transaction) }

      it 'handles concurrent rejections without deadlocks' do
        threads = []
        expect do
          2.times do
            threads << Thread.new do
              begin
                transfer.reject!
              rescue ActiveRecord::RecordNotFound
                # Expected when another thread has already rejected
              end
            end
          end
          threads.each(&:join)
        end.not_to raise_error

        expect(Transfer.exists?(transfer.id)).to be false
        expect(RejectedTransfer.count).to eq(1)
      end
    end

    it 'handles mixed operations without deadlocks' do
      transfer = create(:transfer, inflow_transaction: inflow_transaction, outflow_transaction: outflow_transaction)
      
      threads = []
      expect do
        threads << Thread.new do
          transfer.reject!
        end
        
        threads << Thread.new do
          Transfer.create_transfer!(
            inflow_transaction_id: inflow_transaction.id,
            outflow_transaction_id: outflow_transaction.id
          )
        end
        
        threads.each(&:join)
      end.not_to raise_error
    end
  end

  describe '.from_accounts' do
    it 'creates a transfer with consistent locking' do
      transfer = nil
      expect do
        transfer = Transfer.from_accounts(
          from_account: from_account,
          to_account: to_account,
          date: Date.current,
          amount: Money.new(1000, 'USD')
        )
      end.not_to raise_error

      expect(transfer).to be_persisted
      expect(transfer.inflow_transaction).to be_persisted
      expect(transfer.outflow_transaction).to be_persisted
    end
  end
end
