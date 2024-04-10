# Dynamic settings the user can change within the app (helpful for self-hosting)
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  field :render_deploy_hook, default: ENV["RENDER_DEPLOY_HOOK"], type: :string
end
