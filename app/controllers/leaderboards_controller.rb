class LeaderboardsController < InertiaController
  layout "inertia"

  def index
    period_type = validated_period_type
    leaderboard_scope = validated_leaderboard_scope

    leaderboard = LeaderboardService.get(period: period_type, date: Date.current)

    render inertia: "Leaderboards/Index", props: {
      period_type: period_type.to_s,
      scope: leaderboard_scope.to_s,
      leaderboard: leaderboard_metadata(leaderboard),
      is_logged_in: current_user.present?,
      github_uid_blank: current_user.present? && current_user.github_uid.blank?,
      entries: InertiaRails.defer { entries_payload(leaderboard, leaderboard_scope, period_type) }
    }
  end

  private

  def validated_period_type
    p = (params[:period_type] || "daily").to_s
    %w[daily last_7_days].include?(p) ? p.to_sym : :daily
  end

  # "deltatime": DeltaTime people only. "global": DeltaTime mixed with
  # Hackatime's public leaderboard (read-only). Old ?scope=country links land on DeltaTime.
  def validated_leaderboard_scope
    params[:scope].to_s == "global" ? :global : :deltatime
  end

  def leaderboard_metadata(leaderboard)
    return nil unless leaderboard&.persisted?

    {
      date_range_text: leaderboard.date_range_text,
      updated_at: leaderboard.updated_at&.iso8601,
      finished_generating: leaderboard.finished_generating?,
      generation_duration_seconds: leaderboard.generation_duration_seconds
    }
  end

  def entries_payload(leaderboard, scope, period_type)
    entries = leaderboard&.persisted? ? deltatime_entries(leaderboard) : []
    return { entries: entries, total: entries.size } unless scope == :global

    # Global: everyone on DeltaTime plus Hackatime's public board, by time.
    mixed = (entries + HackatimeLeaderboard.entries(period_type)).sort_by { |e| -e[:total_seconds].to_i }
    { entries: mixed, total: mixed.size }
  end

  def deltatime_entries(leaderboard)
    payload = LeaderboardPageCache.fetch(
      leaderboard: leaderboard,
      scope: :global,
      country_code: nil
    )

    active_projects = Cache::ActiveProjectsJob.perform_now

    visible_entries = payload[:entries].reject do |e|
      e.dig(:user, :red) ||
        (e.dig(:user, :shadowbanned) && e[:user_id] != current_user&.id)
    end

    entries = visible_entries.map do |e|
      user = e[:user]
      proj = active_projects&.dig(e[:user_id])
      {
        user_id: e[:user_id],
        source: "deltatime",
        total_seconds: e[:total_seconds],
        streak_count: e[:streak_count],
        is_current_user: e[:user_id] == current_user&.id,
        user: {
          display_name: user[:display_name],
          avatar_url: user[:avatar_url],
          profile_path: user[:profile_path],
          verified: user[:verified],
          country_code: user[:country_code]
        },
        active_project: proj ? { name: proj.project_name, repo_url: proj.repo_url } : nil
      }
    end

    entries
  end
end
