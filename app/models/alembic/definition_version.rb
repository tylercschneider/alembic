module Alembic
  class DefinitionVersion < ApplicationRecord
    belongs_to :diagnostic
  end
end
