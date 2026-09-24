# Read-only copy of Hackatime's public leaderboard, mixed into DeltaTime's
# "Global" tab. Hackatime serves it without signing in, as an Inertia page:
# first the HTML shell (for the asset version), then the deferred `entries`
# prop as JSON.
#
# Only display fields are kept. Links point back to Hackatime, and nothing is
# ever written anywhere. Results are cached for 10 minutes; if Hackatime is
# down or changes shape, the Global tab just shows DeltaTime alone (failures
# are cached for a minute so we don't hammer it).
class HackatimeLeaderboard
  BASE = "https://hackatime.hackclub.com"
  PERIODS = %w[daily last_7_days].freeze
  TTL = 10.minutes
  FAILURE_TTL = 1.minute
  MAX_ENTRIES = 5000
  USER_AGENT = "DeltaTime leaderboard (https://deltatime.deltavdevs.com)"

  def self.entries(period)
    period = period.to_s
    return [] unless PERIODS.include?(period)

    key = [ "hackatime_leaderboard", "v1", period ]
    cached = Rails.cache.read(key)
    return cached unless cached.nil?

    fetched = fetch(period)
    Rails.cache.write(key, fetched || [], expires_in: fetched ? TTL : FAILURE_TTL)
    fetched || []
  end

  def self.fetch(period)
    path = "/leaderboards?#{{ period_type: period, scope: 'global' }.to_query}"
    http = HTTP.timeout(connect: 5, read: 20).headers("User-Agent" => USER_AGENT)

    shell = http.get("#{BASE}#{path}")
    return nil unless shell.status.success?
    version = CGI.unescapeHTML(shell.body.to_s)[/"version":"([0-9a-f]{8,64})"/, 1]
    return nil unless version

    data = http.headers(
      "X-Inertia" => "true", "X-Inertia-Version" => version,
      "X-Inertia-Partial-Component" => "Leaderboards/Index", "X-Inertia-Partial-Data" => "entries",
      "X-Requested-With" => "XMLHttpRequest", "Accept" => "application/json"
    ).get("#{BASE}#{path}")
    return nil unless data.status.success?

    rows = JSON.parse(data.body.to_s).dig("props", "entries", "entries")
    return nil unless rows.is_a?(Array)

    rows.first(MAX_ENTRIES).filter_map { |row| clean(row) }
  rescue StandardError => e
    Rails.logger.warn("Hackatime leaderboard fetch failed: #{e.class}: #{e.message.to_s.first(200)}")
    nil
  end

  def self.clean(row)
    return nil unless row.is_a?(Hash)
    seconds = row["total_seconds"].to_i
    return nil unless seconds.positive?

    user = row["user"].is_a?(Hash) ? row["user"] : {}
    project = row["active_project"].is_a?(Hash) ? row["active_project"] : nil
    profile = user["profile_path"].to_s
    {
      user_id: "hackatime:#{row['user_id'].to_i}",
      source: "hackatime",
      total_seconds: seconds,
      streak_count: row["streak_count"].to_i,
      is_current_user: false,
      user: {
        display_name: user["display_name"].to_s.first(64).presence || "Hackatime user",
        avatar_url: https_url(user["avatar_url"]),
        # Absolute and external: these people live on Hackatime, not here.
        profile_path: profile.match?(%r{\A/(?!/)[\w@.\-/]{1,100}\z}) ? "#{BASE}#{profile}" : nil,
        verified: false,
        country_code: user["country_code"].to_s.match?(/\A[A-Z]{2}\z/) ? user["country_code"] : nil
      },
      active_project: project && project["name"].present? ? { name: project["name"].to_s.first(100), repo_url: https_url(project["repo_url"]) } : nil
    }
  end

  def self.https_url(value)
    url = value.to_s
    return nil unless url.start_with?("https://") && url.length <= 500
    URI.parse(url).is_a?(URI::HTTPS) ? url : nil
  rescue URI::InvalidURIError
    nil
  end
end
