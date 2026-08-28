module Alembic
  module Flow
    class Terminal
      include Step

      step_name "End"

      ends_here

      setting :heading, type: :string
      setting :message, type: :string

      names_by { |_node| "End" }
    end
  end
end
