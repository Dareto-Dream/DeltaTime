class Settings::GithubController < Settings::BaseController
  private

  def page_props
    {
      github: {
        connected: @user.github_uid.present?,
        username: @user.github_username,
        profile_url: (@user.github_username.present? ? "https://github.com/#{@user.github_username}" : nil)
      }
    }
  end
end
