module Alembic
  module Steps
    class Question
      include Flow::Step

      label "Question"

      setting :text, type: :string
      setting :options, type: :list do
        setting :value, type: :string
        setting :label, type: :string
        setting :weight, type: :integer
      end
      setting :tag, type: :string

      names_by :text
      awaits_input
    end
  end
end
