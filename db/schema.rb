# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111129203246) do

  create_table "alternatives", :force => true do |t|
    t.integer "experiment_id"
    t.string  "content"
    t.string  "lookup",        :limit => 32
    t.integer "weight",                      :default => 1
    t.integer "participants",                :default => 0
    t.integer "conversions",                 :default => 0
  end

  add_index "alternatives", ["experiment_id"], :name => "index_alternatives_on_experiment_id"
  add_index "alternatives", ["lookup"], :name => "index_alternatives_on_lookup"

  create_table "answers", :force => true do |t|
    t.text     "answer"
    t.integer  "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "apn_devices", :force => true do |t|
    t.string   "token",              :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_registered_at"
    t.integer  "user_id"
  end

  add_index "apn_devices", ["token"], :name => "index_apn_devices_on_token", :unique => true

  create_table "apn_notifications", :force => true do |t|
    t.integer  "device_id",                        :null => false
    t.integer  "errors_nb",         :default => 0
    t.string   "device_language"
    t.string   "sound"
    t.string   "alert"
    t.integer  "badge"
    t.text     "custom_properties"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.datetime "resend_at"
  end

  add_index "apn_notifications", ["device_id"], :name => "index_apn_notifications_on_device_id"

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", :force => true do |t|
    t.string   "name",        :limit => 45
    t.text     "html"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "reviewed_at"
    t.datetime "edited_at"
    t.boolean  "public"
    t.integer  "icon_id",                   :default => 0
    t.integer  "price"
  end

  add_index "documents", ["tag_id"], :name => "index_documents_on_tag_id"

  create_table "experiments", :force => true do |t|
    t.string   "test_name"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "experiments", ["test_name"], :name => "index_experiments_on_test_name"

  create_table "lines", :force => true do |t|
    t.string   "domid"
    t.integer  "document_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lines", ["document_id"], :name => "index_lines_on_document_id"

  create_table "mems", :force => true do |t|
    t.float    "strength"
    t.boolean  "status"
    t.integer  "line_id"
    t.integer  "user_id"
    t.datetime "review_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "document_id"
    t.boolean  "pushed",       :default => false
    t.integer  "term_id"
  end

  add_index "mems", ["line_id"], :name => "index_mems_on_line_id"

  create_table "questions", :force => true do |t|
    t.text     "question"
    t.integer  "term_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "topic"
    t.integer  "qb_id"
  end

  create_table "reps", :force => true do |t|
    t.integer  "user_id"
    t.integer  "mem_id"
    t.float    "strength"
    t.float    "confidence"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "mobile",     :default => false
  end

  create_table "resourcerequests", :force => true do |t|
    t.string   "email"
    t.text     "resource"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.string   "name",       :limit => 45
    t.boolean  "misc"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "icon_id",                  :default => 0
    t.integer  "score",                    :default => 0
    t.integer  "rates",                    :default => 0
    t.integer  "price"
  end

  add_index "tags", ["user_id"], :name => "index_tags_on_user_id"

  create_table "terms", :force => true do |t|
    t.integer  "document_id"
    t.integer  "user_id"
    t.integer  "line_id"
    t.text     "name"
    t.text     "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_collections", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",    :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",    :null => false
    t.string   "password_salt",                       :default => "",    :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                     :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                               :default => false
    t.string   "username"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["first_name"], :name => "index_users_on_first_name"
  add_index "users", ["last_name"], :name => "index_users_on_last_name"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  create_table "userships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "document_id"
    t.boolean  "push_enabled", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "owner",        :default => true
    t.datetime "reviewed_at"
  end

end
