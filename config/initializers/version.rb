module Maybe
  class << self
    def version
      Semver.new(semver)
    end

    def commit_sha
      `git rev-parse HEAD`.chomp
    end

    private
      def semver
        "0.0.0" # Placeholder until first release to support self host flow
      end
  end
end
