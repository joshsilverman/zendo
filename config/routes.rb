Zendo::Application.routes.draw do
  
  get "usership/update"

  resources :authentications

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  
  #devise
  devise_for :users, :remember_for => 4.weeks,
    :controllers => {:registrations => 'registrations', :sessions => 'sessions'}

  #tags
  get "tag/index" # ???
  match "/my_eggs" => "tags#index" #** public **#
  match "/tags/create" => "tags#create"
  match "/tags/create_and_assign" => "tags#create"
  match "/tags/update_tags_name"
  match "/tags/create_with_index"

  # documents
  match "/create_from_csv" => "documents#create_from_csv"
  match "/update_from_csv" => "documents#update_from_csv"
  match "/remove_document" => "documents#remove_document"
  match "/upload_csv" => "documents#upload_csv"
  match "/documents/create/:tag_id" => "documents#create"
  match "/documents/update_tag"
  match "/documents/share"
  match "/documents/unshare"
  match "/documents/purchase_doc"
  match "/documents/update_privacy"
  match "/documents/update_document_name"
  match "/documents/update_icon"
  match "/documents/:id/cards" => "documents#cards"
  match "/documents/:id/review_all_cards" => "documents#review_all_cards"
  match "/documents/:id/review_adaptive_cards" => "documents#review_adaptive_cards"
  match "/documents/get_public_documents" => "documents#get_public_documents"
  match "/documents/:id" => "documents#edit", :via => [:get], :read_only => true
  match "/documents/enable_mobile/:id/:bool" => "documents#enable_mobile"
  match "/documents/add_document/:id" => "documents#add_document"
  resources :documents, :only => [:update, :destroy]

  # terms
  match "/terms/lookup/:term" => "terms#lookup"

  # reviewer
  match "/review/:id" => "documents#review" #** public **#
  match "/review/dir/:id" => "tags#review" #** public **#
  match "/mems/update/:id/:confidence/:importance" => "mems#update"
  match "/demo/review/:id" => "demo#review"
  match "/demo/egg_details/:id" => "demo#egg_details"
  resources :lines, :only => [:update]
  
  # organizer
  resources :tags, :only => [:destroy, :create, :update]
  match "/tags/get_tags_json" => "tags#get_tags_json"
  match "/tags/get_popular_json" => "tags#get_popular_json"
  match "/tags/get_recent_json" => "tags#get_recent_json"
  match "/tags/claim_tag/:id" => "tags#claim_tag"
  match "/tags/update_icon" => "tags#update_icon"
  match "/tags/show/:id" => "tags#show"

  # home page
  match "/users/welcome" => "users#home"
  match "/users/has_username" => "users#has_username"
  match "/user" => "tags#index"
  match "/users/autocomplete"
  match "/users/retrieve_notifications"
  match "/users/add_device/:token" => "users#add_device"
  root :to => "users#home"
  root :controller => 'users', :action => 'home'

  # authentications
  match '/auth/:provider/callback' => 'authentications#create'
  match '/users/get_email' => 'users#get_email'
  resources :authentications

  # ajax sign in
  match "/users/simple_sign_in" => "users#simple_sign_in"
  match "/users/update_username" => "users#update_username"

  # search
  #match "/dashboard" => "search#index"
  match "/search/query/:page" => "search#query"
  match "/search/full_query" => "search#full_query"
  match "/search/is_username_available" => "search#is_username_available"

  #abingo dashboard
  match '/abingo(/:action(/:id))' => 'abingo_dash', :as => :abingo

  #store
  match '/store' => 'store#index'
  match '/store/details/:id' => 'store#details'
  match '/store/egg_details/:id' => 'store#egg_details'
  match '/choose_icon/:doc_id' => 'store#choose_icon'

  #static

  match "/about/mission" => "static#mission"
  match "/about/story" => "static#story"
  match "/about/team" => "static#team"
  match "/contact" => "static#contact"

  namespace :user do
    root :controller => 'tags', :action => 'index'
  end

  # catch-all route for static pages
  match ':action', :controller => "static"

  # @important map is deprecated!
  # map.abingoTest "/abingo/:action/:id", :controller=> :abingo_dash
end
