module MaybeFormHelper
  # Returns form_with that uses the MaybeFormBuilder
  def maybe_form_with(**options, &block)
    options[:builder] ||= MaybeFormBuilder
    form_with(**options, &block)
  end
end
