if ENV["INTERCOM_APP_ID"].present? && ENV["INTERCOM_IDENTITY_VERIFICATION_KEY"].present?
  IntercomRails.config do |config|
    # == Intercom app_id
    #
    config.app_id = ENV["INTERCOM_APP_ID"]

    # == Intercom session_duration
    #
    # config.session_duration = 300000
    # == Intercom secret key
    # This is required to enable Identity Verification, you can find it on your Setup
    # guide in the "Identity Verification" step.
    #
    config.api_secret = ENV["INTERCOM_IDENTITY_VERIFICATION_KEY"]

    # == Enabled Environments
    # Which environments is auto inclusion of the Javascript enabled for
    #
    config.enabled_environments = [ "development", "production" ]

    # == Current user method/variable
    # The method/variable that contains the logged in user in your controllers.
    # If it is `current_user` or `@user`, then you can ignore this
    #
    config.user.current = Proc.new { Current.user }

    # == Include for logged out Users
    # If set to true, include the Intercom messenger on all pages, regardless of whether
    # The user model class (set below) is present.
    config.include_for_logged_out_users = true

    # == User model class
    # The class which defines your user model
    #
    # config.user.model = Proc.new { User }

    # == Lead/custom attributes for non-signed up users
    # Pass additional attributes to for potential leads or
    # non-signed up users as an an array.
    # Any attribute contained in config.user.lead_attributes can be used
    # as custom attribute in the application.
    # config.user.lead_attributes = %w(ref_data utm_source)

    # == Exclude users
    # A Proc that given a user returns true if the user should be excluded
    # from imports and Javascript inclusion, false otherwise.
    #
    # config.user.exclude_if = Proc.new { |user| user.deleted? }

    # == User Custom Data
    # A hash of additional data you wish to send about your users.
    # You can provide either a method name which will be sent to the current
    # user object, or a Proc which will be passed the current user.
    #
    config.user.custom_data = {
      family_id: Proc.new { Current.family.id },
      name: Proc.new { Current.user.display_name if Current.user.display_name != Current.user.email }
    }

    # == Current company method/variable
    # The method/variable that contains the current company for the current user,
    # in your controllers. 'Companies' are generic groupings of users, so this
    # could be a company, app or group.
    #
    config.company.current = Proc.new { Current.family }
    #
    # Or if you are using devise you can just use the following config
    #
    # config.company.current = Proc.new { current_user.company }

    # == Exclude company
    # A Proc that given a company returns true if the company should be excluded
    # from imports and Javascript inclusion, false otherwise.
    #
    # config.company.exclude_if = Proc.new { |app| app.subdomain == 'demo' }

    # == Company Custom Data
    # A hash of additional data you wish to send about a company.
    # This works the same as User custom data above.
    #
    # config.company.custom_data = {
    #   :number_of_messages => Proc.new { |app| app.messages.count },
    #   :is_interesting => :is_interesting?
    # }

    # == Company Plan name
    # This is the name of the plan a company is currently paying (or not paying) for.
    # e.g. Messaging, Free, Pro, etc.
    #
    # config.company.plan = Proc.new { |current_company| current_company.plan.name }

    # == Company Monthly Spend
    # This is the amount the company spends each month on your app. If your company
    # has a plan, it will set the 'total value' of that plan appropriately.
    #
    # config.company.monthly_spend = Proc.new { |current_company| current_company.plan.price }
    # config.company.monthly_spend = Proc.new { |current_company| (current_company.plan.price - current_company.subscription.discount) }

    # == Custom Style
    # By default, Intercom will add a button that opens the messenger to
    # the page. If you'd like to use your own link to open the messenger,
    # uncomment this line and clicks on any element with id 'Intercom' will
    # open the messenger.
    #
    # config.inbox.style = :custom
    #
    # If you'd like to use your own link activator CSS selector
    # uncomment this line and clicks on any element that matches the query will
    # open the messenger
    # config.inbox.custom_activator = '.intercom'
    #
    # If you'd like to hide default launcher button uncomment this line
    # config.hide_default_launcher = true
    #
    # If you need to route your Messenger requests through a different endpoint than the default, uncomment the below line. Generally speaking, this is not needed.
    # config.api_base = "https://api-iam.intercom.io"
    #
  end
end
