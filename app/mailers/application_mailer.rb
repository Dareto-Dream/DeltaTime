class ApplicationMailer < ActionMailer::Base
  include Mailkick::UrlHelper

  default from: "Deltatime <#{ENV.fetch("SMTP_FROM_EMAIL", "deltatime@deltavdevs.com")}>"
  layout "mailer"
end
