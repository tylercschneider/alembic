module Alembic
  module Flow
    class Terminal
      include Flow::Step

      step_name "End"

      ends_here
    end
  end
end
