module OauthAuthentication
  extend ActiveSupport::Concern
  include ErrorReporting

  class_methods do
    include ErrorReporting

    def google_authorize_url(redirect_uri, state: nil)
      URI.parse("https://accounts.google.com/o/oauth2/v2/auth?#{{
        client_id: ENV["GOOGLE_CLIENT_ID"],
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: "openid email profile",
        state: state || SecureRandom.hex(24)
      }.to_query}")
    end

    def github_authorize_url(redirect_uri, state: nil)
      URI.parse("https://github.com/login/oauth/authorize?#{{
        client_id: ENV["GITHUB_CLIENT_ID"],
        redirect_uri: redirect_uri,
        state: state || SecureRandom.hex(24),
        scope: "user:email"
      }.to_query}")
    end

    # Signs in (or links, when current_user is given) a Google account. Without
    # a current_user this behaves like a first-class sign-in provider: it finds
    # an existing account by google_uid or verified email, or creates a new one.
    def from_google_token(code, redirect_uri, current_user = nil, ip_address: nil)
      response = HTTP.post("https://oauth2.googleapis.com/token", form: {
        client_id: ENV["GOOGLE_CLIENT_ID"], client_secret: ENV["GOOGLE_CLIENT_SECRET"],
        code: code, redirect_uri: redirect_uri, grant_type: "authorization_code"
      })
      token_data = JSON.parse(response.body.to_s)
      access_token = token_data["access_token"]
      return nil if access_token.nil?

      user_info = JSON.parse(HTTP.auth("Bearer #{access_token}").get("https://www.googleapis.com/oauth2/v3/userinfo").body.to_s)
      google_uid = user_info["sub"]
      return nil if google_uid.blank?

      # Only an address Google has verified may match (or be attached to) an account.
      google_email = user_info["email"].presence if user_info["email_verified"] == true

      target_user = current_user
      target_user ||= User.find_by(google_uid: google_uid)
      target_user ||= (EmailAddress.find_by(email: google_email)&.user if google_email.present?)

      if target_user
        User.where(google_uid: google_uid).where.not(id: target_user.id).where.not(google_access_token: nil).find_each do |user|
          Rails.logger.info "Clearing Google token for User ##{user.id} (Google UID: #{google_uid}) - linking to new account"
          user.update!(google_access_token: nil, google_uid: nil, google_name: nil, google_avatar_url: nil)
        end

        attrs = {
          google_uid: google_uid, google_access_token: access_token,
          google_name: user_info["name"], google_avatar_url: user_info["picture"]
        }
        attrs[:country_code] = country_code_from_ip(ip_address) if target_user.country_code.blank?
        target_user.update!(attrs)
      else
        ActiveRecord::Base.transaction do
          target_user = User.create!(
            google_uid: google_uid, google_access_token: access_token,
            google_name: user_info["name"], google_avatar_url: user_info["picture"],
            country_code: country_code_from_ip(ip_address)
          )
          EmailAddress.create!(email: google_email, user: target_user) if google_email.present?
        end
      end
      target_user
    rescue => e
      report_error(e, message: "Error signing in with Google: #{e.message}")
      nil
    end

    # Signs in (or links, when current_user is given) a GitHub account. Without
    # a current_user this behaves like a first-class sign-in provider: it finds
    # an existing account by github_uid or verified email, or creates a new one.
    def from_github_token(code, redirect_uri, current_user = nil, ip_address: nil)
      response = HTTP.headers(accept: "application/json").post(
        "https://github.com/login/oauth/access_token",
        form: {
          client_id: ENV["GITHUB_CLIENT_ID"],
          client_secret: ENV["GITHUB_CLIENT_SECRET"],
          code: code,
          redirect_uri: redirect_uri
        }
      )
      data = JSON.parse(response.body.to_s)
      return nil unless data["access_token"]

      user_data = JSON.parse(HTTP.auth("Bearer #{data['access_token']}").get("https://api.github.com/user").body.to_s)
      github_uid = user_data["id"]
      github_email = fetch_github_primary_email(data["access_token"])

      target_user = current_user
      target_user ||= User.find_by(github_uid: github_uid)
      target_user ||= (EmailAddress.find_by(email: github_email)&.user if github_email.present?)

      if target_user
        User.where(github_uid: github_uid).where.not(id: target_user.id).where.not(github_access_token: nil).find_each do |user|
          Rails.logger.info "Clearing GitHub token for User ##{user.id} (GitHub UID: #{github_uid}) - linking to new account"
          user.update!(github_access_token: nil, github_uid: nil, github_username: nil)
        end

        target_user.github_uid = github_uid
        target_user.github_username = user_data["login"].presence || user_data["name"].presence
        target_user.github_avatar_url = user_data["avatar_url"]
        target_user.github_access_token = data["access_token"]
        target_user.country_code = country_code_from_ip(ip_address) if target_user.country_code.blank?
        target_user.save!
      else
        ActiveRecord::Base.transaction do
          target_user = User.create!(
            github_uid: github_uid,
            github_username: user_data["login"].presence || user_data["name"].presence,
            github_avatar_url: user_data["avatar_url"],
            github_access_token: data["access_token"],
            country_code: country_code_from_ip(ip_address)
          )
          EmailAddress.create!(email: github_email, user: target_user) if github_email.present?
        end
      end

      ScanGithubReposJob.perform_later(target_user.id)
      target_user
    rescue => e
      report_error(e, message: "Error signing in with GitHub: #{e.message}")
      nil
    end

    def country_code_from_ip(ip_address)
      Geocoder.search(ip_address).first&.country_code.presence&.upcase if ip_address.present?
    rescue => e
      report_error(e, message: "country geocode fail for signup IP")
      nil
    end

    private

    def fetch_github_primary_email(access_token)
      emails = JSON.parse(HTTP.auth("Bearer #{access_token}").get("https://api.github.com/user/emails").body.to_s)
      return nil unless emails.is_a?(Array)

      # Unverified GitHub addresses can be anyone's; never match on them.
      primary = emails.find { |e| e["primary"] && e["verified"] } || emails.find { |e| e["verified"] }
      primary && primary["email"]
    rescue
      nil
    end
  end
end
