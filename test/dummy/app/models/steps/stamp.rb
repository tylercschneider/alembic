module Steps
  class Stamp
    include Alembic::Flow::Step

    step_name "Stamp"

    setting :with, type: :string

    def process(node, _state)
      node.config["with"]
    end
  end
end
