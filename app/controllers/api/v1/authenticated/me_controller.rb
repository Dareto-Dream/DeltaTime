module Api
  module V1
    module Authenticated
      class MeController < ApplicationController
        require_oauth_scope :profile
        skip_before_action :ensure_api_access_allowed, only: :index
        before_action :ensure_no_pending_deletion, only: :index

        def index
          app = doorkeeper_token&.application
          exposed_level = if app&.verified? && app&.confidential?
            current_user.trust_level
          else
            current_user.public_trust_level
          end

          profile = {
            id: current_user.id,
            emails: current_user.email_addresses&.map(&:email)|| [],
            github_username: current_user.github_username,
            trust_factor: {
              trust_level: exposed_level,
              trust_value: User.trust_levels[exposed_level]
            }
          }
          profile[:admin_level] = current_user.admin_level if trusted_admin_application?

          render json: profile
        end

        private

        def trusted_admin_application?
          token = doorkeeper_token
          token&.scopes&.include?("admin") &&
            token.application&.verified? &&
            token.application&.confidential?
        end
      end
    end
  end
end
