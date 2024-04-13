require "test_helper"

class Provider::GithubTest < ActiveSupport::TestCase
  include GitRepositoryProviderInterfaceTest

  setup do
    @subject = Provider::Github.new(owner: "rails", name: "rails", branch: "main")
  end
end
