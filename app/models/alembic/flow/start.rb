module Alembic
  module Flow
    class Start
      include Flow::Step

      step_name "Start"

      begins_here

      names_by { |_node| "Start" }
    end
  end
end
