class DeveloperMessage < Message
  def role
    "developer"
  end

  private
    def broadcast?
      chat.debug_mode?
    end
end
