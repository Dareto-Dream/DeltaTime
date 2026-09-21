class ApplicationMailer < ActionMailer::Base
  include Mailkick::UrlHelper

  default from: "Deltatime <#{ENV.fetch("SMTP_FROM_EMAIL", "deltatime@hackclub.com")}>"
  layout "mailer"
end
