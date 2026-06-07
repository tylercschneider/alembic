Alembic::Engine.routes.draw do
  namespace :manage do
    resources :diagnostics, only: [ :index, :show, :edit, :update ] do
      member do
        post :compile
        post :revert
      end

      resources :questions, only: [ :index, :edit, :update ] do
        resources :options, only: :create
        resource :condition, only: :update
      end
    end
  end

  get ":slug", to: "diagnostics#show", as: :diagnostic
  get ":slug/step", to: "diagnostics#step", as: :diagnostic_step
end
