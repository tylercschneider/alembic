module Alembic
  class ApplicationController < Alembic.base_controller.constantize
    layout -> { Alembic.layout }
    helper KeystoneUiHelper

    rescue_from NotPublished, NotPermitted, with: :refuse

    private

    def admit(diagnostic)
      Admission.of(diagnostic, permitted: permitted?(diagnostic))
    end

    def permitted?(diagnostic)
      return false unless Alembic.visitor_authorization_method

      send(Alembic.visitor_authorization_method, diagnostic)
    end

    def refuse
      head :not_found
    end
  end
end
