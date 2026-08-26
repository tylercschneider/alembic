class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper Rails.application.routes.url_helpers

  def alembic_visitor_permitted?(diagnostic)
    diagnostic.present?
  end
end
