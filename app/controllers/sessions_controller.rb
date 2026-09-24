class SessionsController < ApplicationController
  WARD_REQUIRED = "New DeltaTime accounts are created with Ward. Use Continue with Ward."

  # ---- Ward: the DeltaVDevs account ----
  def ward_new
    return redirect_to(signin_path, alert: "Ward sign-in isn't set up yet.") unless User.ward_configured?

    session[:return_data] = build_return_data(params[:continue]) if params[:continue].present?
    verifier = SecureRandom.urlsafe_base64(48)
    state = SecureRandom.hex(24)
    session[:ward_oauth] = { "state" => state, "verifier" => verifier }
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    redirect_to User.ward_authorize_url(ward_callback_url, state: state, code_challenge: challenge).to_s,
      allow_other_host: User.ward_url
  end

  def ward_create
    pending = session.delete(:ward_oauth) || {}
    back = current_user ? my_settings_connected_accounts_path : signin_path

    if params[:error].present?
      return redirect_to(back, alert: params[:error] == "access_denied" ? "Sign in cancelled" : "Ward sign-in failed. Try again.")
    end

    # State, then RFC 9207: the response has to name Ward as its issuer.
    state_ok = pending["state"].present? && params[:state].present? &&
      ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, pending["state"].to_s)
    unless state_ok && params[:iss].to_s == User.ward_url && params[:code].present?
      report_message("Ward OAuth state or issuer mismatch")
      return redirect_to(back, alert: "Ward sign-in could not be verified. Try again.")
    end

    user, error = User.from_ward_token(params[:code], ward_callback_url, pending["verifier"], current_user, ip_address: client_ip)
    case error
    when :taken then return redirect_to(back, alert: "That Ward account is already linked to a different DeltaTime account.")
    when :other then return redirect_to(back, alert: "This DeltaTime account is already linked to a different Ward account.")
    when :email_exists then return redirect_to(back, alert: "You already have a DeltaTime account with this email. Sign in the old way below, then link Ward in Settings → Connected accounts.")
    when :failed then return redirect_to(back, alert: "Ward sign-in failed. Try again.")
    end

    if current_user
      redirect_to my_settings_connected_accounts_path, notice: "Ward is linked. Sign in with Ward from now on, and remove your old sign-ins below."
    else
      preserved_return_data = session[:return_data]
      reset_session
      session[:user_id] = user.id
      session[:return_data] = preserved_return_data if preserved_return_data
      notice = "Signed in with Ward. Welcome!"
      if user.previously_new_record?
        redirect_to setup_path, notice: notice
      elsif session[:return_data]&.dig("url").present?
        redirect_to session[:return_data].delete("url"), notice: notice
      else
        redirect_to root_path, notice: notice
      end
    end
  end

  def ward_unlink
    return unless require_signed_in!("Please sign in first")

    unless current_user.google_uid.present? || current_user.github_uid.present? || current_user.password_digest.present?
      return redirect_to(my_settings_connected_accounts_path, alert: "Ward is your only way to sign in, so it can't be unlinked.")
    end
    current_user.update!(ward_sub: nil, ward_name: nil, ward_avatar_url: nil)
    redirect_to my_settings_connected_accounts_path, notice: "Ward unlinked."
  end

  # Last step of moving to Ward: drop the old email + password sign-in.
  def remove_password
    return unless require_signed_in!("Please sign in first")
    return redirect_to(my_settings_connected_accounts_path, alert: "Link Ward first, so you can still sign in.") if current_user.ward_sub.blank?

    current_user.update!(password_digest: nil)
    redirect_to my_settings_connected_accounts_path, notice: "Password removed. Sign in with Ward from now on."
  end

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
    return redirect_to(signin_path, alert: WARD_REQUIRED) if @user == :ward_required

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
    return redirect_to(signin_path, alert: WARD_REQUIRED) if @user == :ward_required

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

    return redirect_to(signin_path(continue: continue_param), alert: WARD_REQUIRED) if User.ward_configured?

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
