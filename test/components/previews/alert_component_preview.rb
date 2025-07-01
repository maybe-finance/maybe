class AlertComponentPreview < Lookbook::Preview
  # @param message text
  # @param variant select [info, success, warning, error]
  def default(message: "This is an alert message.", variant: :info)
    render AlertComponent.new(message: message, variant: variant.to_sym)
  end
end