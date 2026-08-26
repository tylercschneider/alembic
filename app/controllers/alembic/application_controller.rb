module Alembic
  class ApplicationController < Alembic.base_controller.constantize
    layout -> { Alembic.layout }
    helper KeystoneUiHelper

    rescue_from NotPublished, NotPermitted, Withdrawn, with: :refuse

    private

    def admit(diagnostic)
      Admission.of(diagnostic, permitted: permitted?(diagnostic))
    end

    def permitted?(diagnostic)
      return false unless Alembic.visitor_authorization_method

      send(Alembic.visitor_authorization_method, diagnostic)
    end

    def refuse(refusal)
      return head :not_found unless Alembic.refusal_method

      send(Alembic.refusal_method, refusal)
    end
  end
end
