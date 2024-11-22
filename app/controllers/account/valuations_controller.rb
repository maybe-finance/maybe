class Account::ValuationsController < ApplicationController
  include EntryableResource

  private
    def builder
      Account::ValuationBuilder.new(entry_params)
    end
end
