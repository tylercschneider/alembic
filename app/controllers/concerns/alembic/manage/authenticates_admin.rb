module Alembic
  module Manage
    module AuthenticatesAdmin
      extend ActiveSupport::Concern

      included do
        before_action :authenticate_admin
      end

      private

      def authenticate_admin
        return unless Alembic.admin_authentication_method

        send(Alembic.admin_authentication_method)
      end
    end
  end
end
