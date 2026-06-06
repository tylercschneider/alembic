Alembic::Engine.routes.draw do
  namespace :manage do
    resources :diagnostics, only: [ :index, :show, :edit, :update ]
  end

  get ":slug", to: "diagnostics#show", as: :diagnostic
  get ":slug/step", to: "diagnostics#step", as: :diagnostic_step
end
