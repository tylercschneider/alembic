module Alembic
  class ApplicationController < Alembic.base_controller.constantize
    layout -> { Alembic.layout }
    helper KeystoneUiHelper

    rescue_from NotPublished, NotPermitted, with: :refuse

    private

    def admit(diagnostic)
      raise NotPublished if diagnostic.nil? || diagnostic.published_definition.blank?
      raise NotPermitted unless permitted?(diagnostic)

      diagnostic
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
