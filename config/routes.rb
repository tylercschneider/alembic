Alembic::Engine.routes.draw do
  namespace :manage do
    resources :diagnostics, only: [ :index, :create, :show, :edit, :update, :destroy ] do
      member do
        post :compile
        post :revert
      end

      resources :questions, only: [ :index, :create, :edit, :update, :destroy ] do
        member do
          post :move_up
          post :move_down
        end

        resources :options, only: :create do
          member do
            post :move_up
            post :move_down
          end
        end

        resource :condition, only: :update
      end

      resources :nodes, only: [ :index, :create, :edit, :update, :destroy ] do
        member do
          post :move_up
          post :move_down
        end

        resources :build_steps, only: :create do
          member do
            post :move_up
            post :move_down
          end
        end
      end

      resources :warnings, only: [ :index, :create, :edit, :update, :destroy ]

      resources :bands, only: [ :index, :create, :edit ]
    end
  end

  get ":slug", to: "diagnostics#show", as: :diagnostic
  get ":slug/step", to: "diagnostics#step", as: :diagnostic_step
end
