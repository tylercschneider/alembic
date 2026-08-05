class AddDomainToAlembicQuestions < ActiveRecord::Migration[8.1]
  def change
    add_reference :alembic_questions, :domain, foreign_key: { to_table: :alembic_domains }
  end
end
