Rails.application.routes.draw do
  mount Alembic::Engine => "/alembic"
end
