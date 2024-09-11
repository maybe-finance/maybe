class InviteCodesController < ApplicationController
  def index
    @invite_codes = InviteCode.all
  end

  def create
    InviteCode.generate!
    redirect_back_or_to invite_codes_path, notice: "Code generated"
  end
end
