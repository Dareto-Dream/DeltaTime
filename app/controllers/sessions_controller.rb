class SessionsController < ApplicationController
  def google_new
    session[:return_data] = build_return_data(params[:continue]) if params[:continue].present?
    redirect_uri = url_for(action: :google_create, only_path: false)
    oauth_nonce = SecureRandom.hex(24)
    session[:google_oauth_state_nonce] = oauth_nonce

    redirect_to User.google_authorize_url(redirect_uri, state: oauth_nonce),
      allow_other_host: "https://accounts.google.com"
  end

  def google_create
    if params[:error].present?
      report_message("Google OAuth error: #{params[:error]}") unless params[:error] == "access_denied"
      alert = params[:error] == "access_denied" ? "Sign in cancelled" : "Failed to authenticate with Google. Error ID: #{Sentry.last_event_id}"
      return redirect_to(current_user ? my_settings_path : root_path, alert: alert)
    end

    unless valid_oauth_state?(provider: "Google", session_key: :google_oauth_state_nonce, received_nonce: params[:state])
      return redirect_to(current_user ? my_settings_path : root_path, alert: "Failed to authenticate with Google")
    end

    redirect_uri = url_for(action: :google_create, only_path: false)
    @user = User.from_google_token(params[:code], redirect_uri, current_user, ip_address: client_ip)

    if @user&.persisted?
      if current_user
        redirect_to my_settings_path, notice: "Successfully linked Google account!"
      else
        preserved_return_data = session[:return_data]
        reset_session
        session[:user_id] = @user.id
        session[:return_data] = preserved_return_data if preserved_return_data
        notice = "Successfully signed in with Google! Welcome!"

        if @user.previously_new_record?
          redirect_to setup_path, notice: notice
        elsif session[:return_data]&.dig("url").present?
          redirect_to session[:return_data].delete("url"), notice: notice
        else
          redirect_to root_path, notice: notice
        end
      end
    else
      report_message("Failed to sign in/link Google account")
      redirect_to(current_user ? my_settings_path : root_path, alert: "Failed to authenticate with Google")
    end
  end

  def google_unlink
    return unless require_signed_in!("Please sign in first")

    current_user.update!(google_access_token: nil, google_uid: nil, google_name: nil, google_avatar_url: nil)
    Rails.logger.info "Google account unlinked for User ##{current_user.id}"
    redirect_to my_settings_path, notice: "Google account unlinked successfully"
  end

  def github_new
    session[:return_data] = build_return_data(params[:continue]) if params[:continue].present?
    redirect_uri = url_for(action: :github_create, only_path: false)
    oauth_nonce = SecureRandom.hex(24)
    session[:github_oauth_state_nonce] = oauth_nonce
    Rails.logger.info "Starting GitHub OAuth flow with redirect URI: #{redirect_uri}"
    redirect_to User.github_authorize_url(redirect_uri, state: oauth_nonce),
                allow_other_host: "https://github.com"
  end

  def github_create
    redirect_uri = url_for(action: :github_create, only_path: false)

    if params[:error].present?
      report_message("GitHub OAuth error: #{params[:error]}") unless params[:error] == "access_denied"
      alert = params[:error] == "access_denied" ? "Sign in cancelled" : "Failed to authenticate with GitHub. Error ID: #{Sentry.last_event_id}"
      return redirect_to(current_user ? my_settings_path : root_path, alert: alert)
    end

    unless valid_oauth_state?(provider: "GitHub", session_key: :github_oauth_state_nonce, received_nonce: params[:state])
      return redirect_to(current_user ? my_settings_path : root_path, alert: "Failed to authenticate with GitHub")
    end

    @user = User.from_github_token(params[:code], redirect_uri, current_user, ip_address: client_ip)

    if @user&.persisted?
      if current_user
        redirect_to my_settings_path, notice: "Successfully linked GitHub account!"
      else
        preserved_return_data = session[:return_data]
        reset_session
        session[:user_id] = @user.id
        session[:return_data] = preserved_return_data if preserved_return_data
        notice = "Successfully signed in with GitHub! Welcome!"

        if @user.previously_new_record?
          redirect_to setup_path, notice: notice
        elsif session[:return_data]&.dig("url").present?
          redirect_to session[:return_data].delete("url"), notice: notice
        else
          redirect_to root_path, notice: notice
        end
      end
    else
      report_message("Failed to sign in/link GitHub account")
      redirect_to(current_user ? my_settings_path : root_path, alert: "Failed to authenticate with GitHub")
    end
  end

  def github_unlink
    return unless require_signed_in!("Please sign in first")

    current_user.update!(github_access_token: nil, github_uid: nil, github_username: nil)
    Rails.logger.info "GitHub account unlinked for User ##{current_user.id}"
    redirect_to my_settings_path, notice: "GitHub account unlinked successfully"
  end

  def signup
    email = params[:email].to_s.strip.downcase
    password = params[:password].to_s
    continue_param = params[:continue].presence

    if email.blank? || !email.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to signin_path(continue: continue_param), alert: "Please enter a valid email address"
    end

    if EmailAddress.exists?(email: email)
      return redirect_to signin_path(continue: continue_param), alert: "An account with that email already exists. Try signing in instead."
    end

    if password.length < 8
      return redirect_to signin_path(continue: continue_param), alert: "Password must be at least 8 characters"
    end

    @user = nil
    ActiveRecord::Base.transaction do
      @user = User.create!(password: password, country_code: User.country_code_from_ip(client_ip))
      @user.email_addresses.create!(email: email, source: :signing_in)
    end

    reset_session
    session[:user_id] = @user.id
    notice = "Account created! Welcome!"
    continue_url = safe_return_url(continue_param)

    if continue_url.present?
      redirect_to continue_url, notice: notice # codeql[rb/url-redirection]
    else
      redirect_to setup_path, notice: notice
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to signin_path(continue: continue_param), alert: e.record.errors.full_messages.to_sentence.presence || "Couldn't create your account"
  end

  def login
    email = params[:email].to_s.strip.downcase
    password = params[:password].to_s
    continue_param = params[:continue].presence

    email_address = EmailAddress.find_by(email: email)
    @user = email_address&.user

    unless @user&.authenticate(password)
      return redirect_to signin_path(continue: continue_param, sign_in_email: true), alert: "Incorrect email or password"
    end

    reset_session
    session[:user_id] = @user.id
    notice = "Successfully signed in! Welcome back!"
    continue_url = safe_return_url(continue_param)

    if continue_url.present?
      redirect_to continue_url, notice: notice # codeql[rb/url-redirection]
    else
      redirect_to root_path, notice: notice
    end
  end

  def add_email
    return unless require_signed_in!("Please sign in first to add an email")

    email = params[:email].to_s.strip.downcase
    if EmailAddress.exists?(email: email)
      return redirect_to(my_settings_path, alert: "#{email} is already linked to an account.")
    end

    current_user.email_addresses.create!(email: email, source: :signing_in)
    redirect_to my_settings_path, notice: "Added #{email} to your account."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to my_settings_path, alert: "Couldn't add #{email}: #{e.record.errors.full_messages.join(', ')}."
  end

  def unlink_email
    return unless require_signed_in!("Please sign in first to unlink an email")

    email = params[:email].downcase
    email_record = current_user.email_addresses.find_by(email: email)
    return redirect_to(my_settings_path, alert: "#{email} isn't linked to your account.") unless email_record

    unless current_user.can_delete_email_address?(email_record)
      return redirect_to(my_settings_path, alert: "You can only unlink emails that are used for signing in.")
    end

    email_record.destroy!
    redirect_to my_settings_path, notice: "Unlinked #{email} from your account."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to my_settings_path, alert: "Couldn't unlink #{email}: #{e.record.errors.full_messages.join(', ')}."
  end

  def impersonate
    return unless require_admin!(alert: "You are not authorized to impersonate users")

    user = User.find_by(id: params[:id])
    return redirect_to(root_path, alert: "who?") unless user

    return redirect_to(root_path, alert: "nice try, you cant do that") unless current_user.can_impersonate?(user)

    session[:impersonater_user_id] ||= current_user.id
    session[:user_id] = user.id
    redirect_to root_path, notice: "Impersonating #{user.display_name}"
  end

  def stop_impersonating
    session[:user_id] = session[:impersonater_user_id]
    session[:impersonater_user_id] = nil
    redirect_to root_path, notice: "Stopped impersonating"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out!"
  end

  private

  def client_ip = request.headers["CF-Connecting-IP"].presence || request.remote_ip

  def valid_oauth_state?(provider:, session_key:, received_nonce:)
    expected_nonce = session.delete(session_key)

    if expected_nonce.blank? || received_nonce.blank?
      report_message("#{provider} OAuth state missing expected=#{expected_nonce.present?} received=#{received_nonce.present?}")
      return false
    end

    return true if ActiveSupport::SecurityUtils.secure_compare(received_nonce.to_s, expected_nonce.to_s)

    report_message("#{provider} OAuth state mismatch")
    false
  end

  # Handles OAuth callback errors. Returns true if a redirect was performed.
  def handle_oauth_error(provider, redirect_path:, alert_label:)
    return false if params[:error].blank?

    if params[:error] == "access_denied"
      redirect_to redirect_path, alert: "Sign in cancelled"
      return true
    end

    report_message("#{provider} OAuth error: #{params[:error]}")
    redirect_to redirect_path, alert: "Failed to authenticate with #{alert_label}. Error ID: #{Sentry.last_event_id}"
    true
  end
end
