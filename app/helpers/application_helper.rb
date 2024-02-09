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
  def modal
    # Save the current virtual path so we can restore it after rendering the modal
    # This ensures translations are scoped to the current view appropriately
    path = @virtual_path

    render "shared/modal" do
      @virtual_path = path
      yield
    end
  end
end
