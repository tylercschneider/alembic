module Steps
  class Deliver
    include Alembic::Flow::Step

    step_name "Deliver"

    setting :message, type: :string
    setting :to, type: :string

    requires { |node| [ node.config["to"] ].compact }

    def process(node, state)
      state[node.config["to"]].present?
    end
  end
end
