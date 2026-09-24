require "test_helper"
require "webmock/minitest"

# Other apps reading DeltaTime stats with a Ward token (scope `deltatime`).
class WardTokenTest < ActionDispatch::IntegrationTest
  WARD = "https://ward.test"

  setup do
    @env = ENV.to_h.slice("WARD_URL", "WARD_CLIENT_ID", "WARD_CLIENT_SECRET")
    ENV["WARD_URL"] = WARD
    ENV["WARD_CLIENT_ID"] = "deltatime-client"
    ENV["WARD_CLIENT_SECRET"] = "deltatime-secret"
    @user = User.create!(ward_sub: "66666666-6666-4666-8666-666666666666", ward_name: "Stats Person", username: "statsperson")
  end

  teardown do
    %w[WARD_URL WARD_CLIENT_ID WARD_CLIENT_SECRET].each { |k| @env.key?(k) ? ENV[k] = @env[k] : ENV.delete(k) }
  end

  def introspection(body)
    stub_request(:post, "#{WARD}/oauth/introspect")
      .with(basic_auth: [ "deltatime-client", "deltatime-secret" ])
      .to_return(body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def active(overrides = {})
    { active: true, iss: WARD, scope: "deltatime", sub: @user.ward_sub, exp: 1.hour.from_now.to_i }.merge(overrides)
  end

  test "a ward token with the deltatime scope reads the linked account" do
    introspection(active)
    get "/api/v1/ward/me", headers: { "Authorization" => "Bearer wat_good" }
    assert_response :success
    assert_equal @user.id, response.parsed_body["id"]

    get "/api/v1/users/my/heartbeats/spans", headers: { "Authorization" => "Bearer wat_good" }
    assert_response :success
  end

  test "tokens Ward says are inactive, lack the scope, or come from elsewhere are refused" do
    [ { active: false }, active(scope: "openid profile"), active(iss: "https://evil.example"), active(exp: 1.minute.ago.to_i), active(sub: "77777777-7777-4777-8777-777777777777") ].each do |body|
      WebMock.reset!
      introspection(body)
      get "/api/v1/ward/me", headers: { "Authorization" => "Bearer wat_#{SecureRandom.hex(4)}" }
      assert_response :unauthorized, body.inspect
    end
  end

  test "ward tokens can't write heartbeats" do
    introspection(active)
    post "/api/deltatime/v1/users/current/heartbeats", params: { time: Time.now.to_f, entity: "x.rb", type: "file" }.to_json,
      headers: { "Authorization" => "Bearer wat_good", "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end
