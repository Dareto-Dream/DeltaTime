Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.ignore_actions = [ "Api::Deltatime::V1::DeltatimeController#push_heartbeats" ]
  config.lograge.ignore_custom = lambda do |event|
    event.payload[:path] == "/up"
  end
end
