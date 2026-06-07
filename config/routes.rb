Alembic::Engine.routes.draw do
  namespace :manage do
    resources :diagnostics, only: [ :index, :show, :edit, :update ] do
      member do
        post :compile
        post :revert
      end

      resources :questions, only: :index
    end
  end

  get ":slug", to: "diagnostics#show", as: :diagnostic
  get ":slug/step", to: "diagnostics#step", as: :diagnostic_step
end
