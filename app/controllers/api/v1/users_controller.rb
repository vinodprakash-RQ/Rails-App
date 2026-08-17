module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      def me
        render json: { data: { id: current_user.id, email: current_user.email, created_at: current_user.created_at } }
      end
    end
  end
end
