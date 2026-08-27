module Alembic
  module Flow
    class Terminal
      include Step

      step_name "End"

      ends_here

      names_by { |_node| "End" }
    end
  end
end
