module Alembic
  module Steps
    class Question
      include Flow::Step

      label "Question"

      setting :text, type: :string
      setting :options, type: :records, of: { value: :string, label: :string, weight: :integer }
      setting :tag, type: :string

      names_by :text
      awaits_input
    end
  end
end
