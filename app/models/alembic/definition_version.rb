module Alembic
  class DefinitionVersion < ApplicationRecord
    belongs_to :diagnostic

    validates :number, uniqueness: true
  end
end
