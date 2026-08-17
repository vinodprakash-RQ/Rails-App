module Api
  module V1
    class AuthController < ApplicationController
      def register
        user = User.new(user_params)
        return render_validation_errors(user) unless user.save
        render json: { data: { user: user_json(user), token: issue_token(user) } }, status: :created
      end

      def login
        user = User.find_by(email: params.require(:email).to_s.strip.downcase)
        return render json: { error: { code: "invalid_credentials", message: "Email or password is invalid" } }, status: :unauthorized unless user&.authenticate(params.require(:password))
        render json: { data: { user: user_json(user), token: issue_token(user) } }
      end

      private

      def user_params
        params.permit(:email, :password, :password_confirmation)
      end

      def user_json(user)
        { id: user.id, email: user.email, created_at: user.created_at }
      end
    end
  end
end
