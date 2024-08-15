class IssuesController < ApplicationController
  layout :with_sidebar

  before_action :set_issue, only: :show

  def show
  end

  private

    def set_issue
      @issue = Current.family.issues.find(params[:id])
    end
end
