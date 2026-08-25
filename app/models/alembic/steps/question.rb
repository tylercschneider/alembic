module Alembic
  module Steps
    class Question
      include Flow::Step

      label "Question"

      setting :text, type: :text
      setting :options, type: :records, of: { value: :string, label: :string, weight: :number }
      setting :tag, type: :string

      names_by :text
      awaits_input
    end
  end
end
