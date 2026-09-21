class Api::V1::UsersController < ApplicationController
  before_action :authenticate_admin_api_key!, unless: -> { Rails.env.development? }

  def lookup_email
    user = EmailAddress.find_by(email: params[:email])&.user
    if user.present?
      render json: { user_id: user.id, email: params[:email] }
    else
      render json: { error: "User not found", email: params[:email] }, status: :not_found
    end
  end
end
