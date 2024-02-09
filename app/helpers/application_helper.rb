module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def header_title(page_title)
    content_for(:header_title) { page_title }
  end

  def permitted_accountable_partial(name)
    name.underscore
  end

  # Wrap view with <%= modal do %> ... <% end %> to have it open in a modal
  # Make sure to add data-turbo-frame="modal" to the link/button that opens the modal
  def modal(&block)
    content = capture &block
    render partial: "shared/modal", locals: { content: content }
  end

  def currency_dropdown(f: nil, options: [])
    render partial: "shared/currency_dropdown", locals: { f: f, options: options }
  end
end
