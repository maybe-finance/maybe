class IssuesController < ApplicationController
  before_action :set_issue, only: :show

  def show
    render template: "#{@issue.class.name.underscore.pluralize}/show", layout: "issues"
  end

  private

    def set_issue
      @issue = Current.family.issues.find(params[:id])
    end
end
