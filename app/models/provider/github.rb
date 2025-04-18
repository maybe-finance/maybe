class Provider::Github
  attr_reader :name, :owner, :branch

  def initialize
    @name = "maybe"
    @owner = "maybe-finance"
    @branch = "main"
  end

  def fetch_latest_release_notes
    begin
      Rails.cache.fetch("latest_github_release_notes", expires_in: 2.hours) do
        release = Octokit.releases(repo).first
        if release
          {
            avatar: release.author.avatar_url,
            # this is the username, it would be nice to get the full name
            username: release.author.login,
            name: release.name,
            published_at: release.published_at,
            body: Octokit.markdown(release.body, mode: "gfm", context: repo)
          }
        else
          nil
        end
      end
    rescue => e
      Rails.logger.error "Failed to fetch latest GitHub release notes: #{e.message}"
      nil
    end
  end

  private
    def repo
      "#{owner}/#{name}"
    end
end
