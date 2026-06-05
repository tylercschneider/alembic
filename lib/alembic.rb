require "alembic/version"
require "alembic/engine"

module Alembic
  class << self
    attr_writer :layout

    # The host app sets this to render the engine inside its own layout
    # (e.g. "marketing"). Defaults to the engine's own layout.
    def layout
      @layout || "alembic/application"
    end
  end
end
