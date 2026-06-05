require "json"
require "alembic/version"
require "alembic/engine"

module Alembic
  class << self
    attr_writer :layout, :base_controller
    attr_accessor :lead_partial

    def bundled_definition(slug)
      file = "alembic/definitions/#{slug.tr('-', '_')}.json"
      JSON.parse(File.read(File.expand_path(file, __dir__)))
    end

    def seed!
      Dir[File.expand_path("alembic/definitions/*.json", __dir__)].each do |file|
        Diagnostic.upsert_definition(JSON.parse(File.read(file)))
      end
    end

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
  end
end
