# Who am I on DeltaTime, for an app holding a Ward token with the `deltatime`
# scope. Apps use it to find the DeltaTime account behind a Ward sign-in
# (SynthCity matches old accounts this way). Ward tokens only.
class Api::V1::WardController < ActionController::API
  def me
    token = request.headers["Authorization"].to_s[/\ABearer\s+(\S+)\z/i, 1]
    user = WardToken.user_for(token) if WardToken.ward_token?(token)
    return render(json: { error: "No DeltaTime account is linked to this Ward account, or the token lacks the deltatime scope." }, status: :unauthorized) unless user
    return render(json: { error: "Unauthorized" }, status: :unauthorized) if user.api_access_restricted?

    render json: { id: user.id, username: user.username, display_name: user.display_name }
  end
end
