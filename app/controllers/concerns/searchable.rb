module Searchable
  extend ActiveSupport::Concern

  included do
    before_action :set_search_session_key
  end

  private

    def set_search_session_key
      @search_session_key = "#{get_session_key_prefix}_search_params"
    end

    def search_params
      session[@search_session_key] || {}
    end

    def update_search_params(new_params)
      session[@search_session_key] = search_params.merge(new_params)
    end

    def clear_search
      session[@search_session_key] = nil
    end

    def remove_search_param(param_key)
      current_params = search_params
      current_params.delete(param_key)
      session[@search_session_key] = current_params
    end

    def get_session_key_prefix
      controller_path.split("/").first
    end
end
