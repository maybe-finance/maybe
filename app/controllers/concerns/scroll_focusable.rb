module ScrollFocusable
  extend ActiveSupport::Concern

  def set_focused_record(record_scope, record_id, default_per_page: 10)
    return unless record_id.present?

    @focused_record = record_scope.find_by(id: record_id)

    record_index = record_scope.pluck(:id).index(record_id)

    return unless record_index

    page_of_focused_record = (record_index / (params[:per_page]&.to_i || default_per_page)) + 1

    if params[:page]&.to_i != page_of_focused_record
      (
        redirect_to(url_for(page: page_of_focused_record, focused_record_id: record_id))
      )
    end
  end
end
