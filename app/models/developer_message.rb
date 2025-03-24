class DeveloperMessage < Message
  def role
    "developer"
  end

  def broadcast?
    chat.debug_mode?
  end
end
