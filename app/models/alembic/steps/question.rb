module Alembic
  module Steps
    class Question
      include Flow::Step

      label "Question"

      setting :text, type: :text
      setting :options, type: :records, of: { value: :text, label: :text, weight: :integer }
      setting :tag, type: :text

      names_by :text
      awaits_input
    end
  end
end
