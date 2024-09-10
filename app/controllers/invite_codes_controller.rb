class InviteCodesController < ApplicationController
  def index
    @invite_codes = fetch_invite_codes
    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace("invite_codes", partial: "invite_codes") }
    end
  end

  private

    def fetch_invite_codes
      InviteCode.pluck(:token).presence || [ InviteCode.generate! ]
    end
end
