require "test_helper"
require "uri"
require "webmock/minitest"

# Ward (ward.deltavdevs.com) sign-in: PKCE, state and issuer checks, new
# accounts only through Ward, and old accounts linking Ward instead of
# getting duplicated.
class WardAuthTest < ActionDispatch::IntegrationTest
  WARD = "https://ward.test"

  setup do
    @env = ENV.to_h.slice("WARD_URL", "WARD_CLIENT_ID", "WARD_CLIENT_SECRET")
    ENV["WARD_URL"] = WARD
    ENV["WARD_CLIENT_ID"] = "deltatime-client"
    ENV["WARD_CLIENT_SECRET"] = "deltatime-secret"
  end

  teardown do
    %w[WARD_URL WARD_CLIENT_ID WARD_CLIENT_SECRET].each { |k| @env.key?(k) ? ENV[k] = @env[k] : ENV.delete(k) }
  end

  def stub_ward(profile)
    stub_request(:post, "#{WARD}/oauth/token")
      .with { |req| URI.decode_www_form(req.body).to_h["code_verifier"].present? }
      .to_return(body: { access_token: "wat_test", token_type: "Bearer" }.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{WARD}/oauth/userinfo")
      .with(headers: { "Authorization" => "Bearer wat_test" })
      .to_return(body: profile.to_json, headers: { "Content-Type" => "application/json" })
  end

  def ward_round_trip(iss: WARD)
    get ward_auth_path
    assert_response :redirect
    authorize = URI.parse(response.location)
    params = URI.decode_www_form(authorize.query).to_h
    assert_equal "#{WARD}/oauth/authorize", "#{authorize.scheme}://#{authorize.host}#{authorize.path}"
    assert_equal "S256", params["code_challenge_method"]
    assert_equal "deltatime-client", params["client_id"]
    get ward_callback_path(state: params["state"], code: "c0de", iss: iss)
  end

  def legacy_user(email)
    user = User.create!(password: "old password 123")
    user.email_addresses.create!(email: email)
    user
  end

  test "a new person signs up through Ward" do
    stub_ward(sub: "11111111-1111-4111-8111-111111111111", email: "fresh@example.com", email_verified: true, name: "Fresh")
    assert_difference -> { User.count }, 1 do
      ward_round_trip
    end
    user = User.find_by!(ward_sub: "11111111-1111-4111-8111-111111111111")
    assert_equal user.id, session[:user_id]
    assert_equal "Fresh", user.display_name
    assert user.email_addresses.exists?(email: "fresh@example.com")
  end

  test "a response that does not name Ward as its issuer is refused" do
    stub_ward(sub: "22222222-2222-4222-8222-222222222222", email_verified: false)
    assert_no_difference -> { User.count } do
      ward_round_trip(iss: "https://evil.example")
    end
    assert_nil session[:user_id]
    assert_match(/could not be verified/, flash[:alert])
  end

  test "a forged callback without the state is refused" do
    get ward_callback_path(state: "forged", code: "c0de", iss: WARD)
    assert_nil session[:user_id]
    assert_match(/could not be verified/, flash[:alert])
  end

  test "an existing account is never merged by email" do
    legacy_user("old@example.com")
    stub_ward(sub: "33333333-3333-4333-8333-333333333333", email: "old@example.com", email_verified: true, name: "Old")
    assert_no_difference -> { User.count } do
      ward_round_trip
    end
    assert_nil session[:user_id]
    assert_match(/Sign in the old way/, flash[:alert])
  end

  test "an old account signs in the old way, links Ward, then drops its password" do
    user = legacy_user("linker@example.com")
    post login_auth_path, params: { email: "linker@example.com", password: "old password 123" }
    assert_equal user.id, session[:user_id]

    stub_ward(sub: "44444444-4444-4444-8444-444444444444", email: "linker@example.com", email_verified: true, name: "Linker")
    ward_round_trip
    assert_redirected_to my_settings_connected_accounts_path
    assert_equal "44444444-4444-4444-8444-444444444444", user.reload.ward_sub

    delete remove_password_auth_path
    assert_nil user.reload.password_digest

    # Next time Ward opens the same old account.
    delete signout_path
    ward_round_trip
    assert_equal user.id, session[:user_id]
  end

  test "Ward can't be unlinked when it's the only way in" do
    stub_ward(sub: "55555555-5555-4555-8555-555555555555", email: "only@example.com", email_verified: true)
    ward_round_trip
    user = User.find_by!(ward_sub: "55555555-5555-4555-8555-555555555555")
    delete ward_unlink_path
    assert_equal "55555555-5555-4555-8555-555555555555", user.reload.ward_sub
  end

  test "email sign-up is closed once Ward is on" do
    assert_no_difference -> { User.count } do
      post signup_auth_path, params: { email: "new@example.com", password: "long enough password" }
    end
    assert_match(/created with Ward/, flash[:alert])
  end

  test "legacy GitHub sign-in ignores unverified emails and can't create accounts" do
    victim = legacy_user("victim@example.com")
    stub_request(:post, "https://github.com/login/oauth/access_token").to_return(body: { access_token: "gh" }.to_json)
    stub_request(:get, "https://api.github.com/user").to_return(body: { id: 999, login: "attacker" }.to_json)
    stub_request(:get, "https://api.github.com/user/emails")
      .to_return(body: [ { email: "victim@example.com", primary: true, verified: false } ].to_json)

    result = User.from_github_token("code", "https://deltatime.test/auth/github/callback")
    assert_equal :ward_required, result, "no verified email match and Ward is on: refuse"
    assert_nil victim.reload.github_uid, "the unverified address must not reach the victim's account"
  end
end
