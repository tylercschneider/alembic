module Alembic
  module Steps
    class Switch
      include Flow::Step

      step_name "Switch"

      setting :step, type: :previous_step
    end
  end
end
