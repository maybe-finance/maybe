class SyncPlaidInstitutionsJob < ApplicationJob

  def perform_now
    # Get all institutions from Plaid, which includes paginating through all pages
    offset = 0
    while true
      institutions = []

      institutions_get_request = Plaid::InstitutionsGetRequest.new({
        offset: offset,
        count: 500,
        country_codes: ['US', 'CA'],
        options: {
          include_optional_metadata: true
        }
      })
      response = $plaid_api_client.institutions_get(institutions_get_request)
      institutions += response.institutions

      # Upsert institutions in our database
      all_institutions = []
      institutions.each do |institution|
        all_institutions << {
          name: institution.name,
          provider: 'plaid',
          provider_id: institution.institution_id,
          logo: institution.logo,
          color: institution.primary_color,
          url: institution.url,
        }
      end

      Institution.upsert_all(all_institutions, unique_by: :provider_id)

      offset += 500
      break if response.institutions.length < 500
    end
  end
end
