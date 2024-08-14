class Account::IssuesController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_issue, only: :show

  def index
    @issues = @account.issues.ordered
  end

  def show
    render @issue.class.name.underscore
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_issue
      @issue = @account.issues.find(params[:id])
    end
end
