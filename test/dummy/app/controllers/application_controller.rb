class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper Rails.application.routes.url_helpers

  def note_the_refusal(refusal)
    response.headers["X-Refusal"] = refusal.class.name
    head :forbidden
  end

  def send_a_refused_visitor_to_login(_refusal)
    redirect_to "/host-login"
  end

  def alembic_visitor_permitted?(diagnostic)
    diagnostic.present?
  end
end
