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
        "0.1.0"
      end
  end
end
