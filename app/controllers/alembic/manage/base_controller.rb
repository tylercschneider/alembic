module Alembic
  module Manage
    class BaseController < Alembic.base_controller.constantize
      before_action :authenticate_admin

      layout -> { Alembic.admin_layout }

      helper KeystoneUiHelper

      private

      def authenticate_admin
        return unless Alembic.admin_authentication_method

        send(Alembic.admin_authentication_method)
      end
    end
  end
end
