module InstitutionsHelper
  def institution_logo(institution)
    institution.logo.attached? ? institution.logo : institution.logo_url
  end
end
