require "test_helper"
require "webmock/minitest"

class HackatimeLeaderboardTest < ActiveSupport::TestCase
  BASE = HackatimeLeaderboard::BASE
  SHELL = %(<html><div id="app" data-page="{&quot;component&quot;:&quot;Leaderboards/Index&quot;,&quot;version&quot;:&quot;7cdda54426881b8a&quot;}"></div></html>)

  def stub_hackatime(entries, status: 200)
    stub_request(:get, "#{BASE}/leaderboards?period_type=daily&scope=global")
      .with { |req| req.headers["X-Inertia-Partial-Data"].nil? }
      .to_return(status: 200, body: SHELL)
    stub_request(:get, "#{BASE}/leaderboards?period_type=daily&scope=global")
      .with(headers: { "X-Inertia" => "true", "X-Inertia-Version" => "7cdda54426881b8a", "X-Inertia-Partial-Data" => "entries" })
      .to_return(status: status, body: { props: { entries: { entries: entries, total: entries.size } } }.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "keeps display fields only, links out, and refuses unsafe urls" do
    stub_hackatime([
      { user_id: 7, total_seconds: 3600, streak_count: 2, is_current_user: true,
        user: { display_name: "Ambush", avatar_url: "https://avatars.example/a.png", profile_path: "/@ambush", verified: true, country_code: "US", email: "leak@example.com" },
        active_project: { name: "LogLens", repo_url: "https://github.com/x/LogLens" } },
      { user_id: 8, total_seconds: 60, streak_count: 0,
        user: { display_name: "<script>", avatar_url: "javascript:alert(1)", profile_path: "//evil.example", country_code: "nope" },
        active_project: { name: "p", repo_url: "http://insecure.example" } },
      { user_id: 9, total_seconds: 0, user: { display_name: "zero" } }
    ])

    rows = HackatimeLeaderboard.entries(:daily)
    assert_equal 2, rows.size, "zero-time rows are dropped"
    first, second = rows
    assert_equal "hackatime:7", first[:user_id]
    assert_equal "hackatime", first[:source]
    assert_equal false, first[:is_current_user]
    assert_equal false, first.dig(:user, :verified), "Hackatime verification isn't DeltaTime verification"
    assert_equal "#{BASE}/@ambush", first.dig(:user, :profile_path)
    assert_nil first[:user][:email], "only whitelisted fields survive"
    assert_nil second.dig(:user, :avatar_url)
    assert_nil second.dig(:user, :profile_path)
    assert_nil second.dig(:user, :country_code)
    assert_nil second.dig(:active_project, :repo_url)
  end

  test "Hackatime being down just means no Hackatime rows" do
    stub_hackatime([], status: 500)
    assert_equal [], HackatimeLeaderboard.entries(:daily)
    assert_equal [], HackatimeLeaderboard.entries(:yearly), "unknown periods never hit the network"
  end

  test "global mixes both boards by time; deltatime stays DeltaTime-only" do
    stub_hackatime([ { user_id: 1, total_seconds: 500, user: { display_name: "ht" } } ])
    controller = LeaderboardsController.new
    global = controller.send(:entries_payload, nil, :global, :daily)
    assert_equal [ "hackatime:1" ], global[:entries].map { |e| e[:user_id] }
    deltatime = controller.send(:entries_payload, nil, :deltatime, :daily)
    assert_equal 0, deltatime[:total]
  end
end
