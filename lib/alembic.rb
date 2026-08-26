require "json"
require "alembic/version"
require "alembic/engine"

module Alembic
  class NotPublished < StandardError; end
  class NotPermitted < StandardError; end
  class OutOfService < StandardError; end

  class << self
    attr_writer :layout, :base_controller, :admin_layout
    attr_accessor :lead_partial, :admin_authentication_method, :visitor_authorization_method, :refusal_method

    # The host app sets this to render the engine inside its own layout
    # (e.g. "marketing"). Defaults to the engine's own layout.
    def layout
      @layout || "alembic/application"
    end

    # The host app sets this (e.g. "ApplicationController") so the engine's
    # controllers inherit the host's helpers, layout chrome, and concerns.
    # Defaults to a plain controller.
    def base_controller
      @base_controller || "ActionController::Base"
    end

    # The host app sets this to render the builder inside its own admin
    # chrome. Defaults to the conventional application layout.
    def admin_layout
      @admin_layout || "application"
    end
  end
end
