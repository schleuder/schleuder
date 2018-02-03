# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180202183800) do

  create_table "accounts", force: :cascade do |t|
    t.string "email",    null: false
    t.string  "password_digest",                 null: false
  end

  add_index "accounts", ["email"], name: "index_accounts_on_email", unique: true

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                                       limit: 255
    t.string   "fingerprint",                                 limit: 255
    t.string   "log_level",                                   limit: 255, default: "warn"
    t.string   "subject_prefix",                              limit: 255, default: ""
    t.string   "subject_prefix_in",                           limit: 255, default: ""
    t.string   "subject_prefix_out",                          limit: 255, default: ""
    t.string   "openpgp_header_preference",                   limit: 255, default: "signencrypt"
    t.text     "public_footer",                                           default: ""
    t.text     "headers_to_meta",                                         default: "[\"from\", \"to\", \"cc\", \"date\", \"sig\", \"enc\"]"
    t.text     "bounces_drop_on_headers",                                 default: "{\"x-spam-flag\":\"yes\"}"
    t.text     "keywords_admin_only",                                     default: "[\"subscribe\", \"unsubscribe\", \"delete-key\"]"
    t.text     "keywords_admin_notify",                                   default: "[\"add-key\"]"
    t.boolean  "send_encrypted_only",                                     default: true
    t.boolean  "receive_encrypted_only",                                  default: false
    t.boolean  "receive_signed_only",                                     default: false
    t.boolean  "receive_authenticated_only",                              default: false
    t.boolean  "receive_from_subscribed_emailaddresses_only",             default: false
    t.boolean  "receive_admin_only",                                      default: false
    t.boolean  "keep_msgid",                                              default: true
    t.boolean  "bounces_drop_all",                                        default: false
    t.boolean  "bounces_notify_admins",                                   default: true
    t.boolean  "include_list_headers",                                    default: true
    t.boolean  "include_openpgp_header",                                  default: true
    t.integer  "max_message_size_kb",                                     default: 10240
    t.string   "language",                                    limit: 255, default: "en"
    t.boolean  "forward_all_incoming_to_admins",                          default: false
    t.integer  "logfiles_to_keep",                                        default: 2
    t.text     "internal_footer",                                         default: ""
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "list_id"
    t.string   "email",            limit: 255
    t.string   "fingerprint",      limit: 255
    t.boolean  "admin",                        default: false
    t.boolean  "delivery_enabled",             default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["email", "list_id"], name: "index_subscriptions_on_email_and_list_id", unique: true
  add_index "subscriptions", ["list_id"], name: "index_subscriptions_on_list_id"

end
