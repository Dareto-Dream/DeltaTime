class OnboardingMailer < ApplicationMailer
  layout false

  def welcome(user, recipient_email:)
    @user = user
    # mail(
    #   to: recipient_email,
    #   subject: "Welcome to Deltatime!"
    # )
  end

  def check_in(user, recipient_email:)
    @user = user
    from_email = ENV.fetch("ONBOARDING_CHECK_IN_FROM_EMAIL", "Deltatime <deltatime@deltavdevs.com>")
    reply_to = "deltatime@deltavdevs.com"

    mail(
      to: recipient_email,
      from: from_email,
      cc: from_email,
      reply_to:,
      subject: "How're you finding Deltatime?"
    )
  end
end
