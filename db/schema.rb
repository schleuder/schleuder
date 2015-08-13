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

ActiveRecord::Schema.define(version: 20150812165700) do

  create_table "lists", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "fingerprint"
    t.string   "gpg_passphrase"
    t.string   "log_level",                                   default: "warn"
    t.string   "default_mime",                                default: "mime"
    t.string   "subject_prefix",                              default: ""
    t.string   "subject_prefix_in",                           default: ""
    t.string   "subject_prefix_out",                          default: ""
    t.string   "openpgp_header_preference",                   default: "signencrypt"
    t.text     "public_footer",                               default: ""
    t.text     "headers_to_meta",                             default: "[\"from\",\"to\",\"date\",\":cc\"]"
    t.text     "bounces_drop_on_headers",                     default: "{\"x-spam-flag\":\"yes\"}"
    t.text     "keywords_admin_only",                         default: "[\"subscribe\", \"unsubscribe\", \"delete-key\"]"
    t.text     "keywords_admin_notify",                       default: "[\"add-key\"]"
    t.boolean  "send_encrypted_only",                         default: false
    t.boolean  "receive_encrypted_only",                      default: false
    t.boolean  "receive_signed_only",                         default: false
    t.boolean  "receive_authenticated_only",                  default: false
    t.boolean  "receive_from_subscribed_emailaddresses_only", default: false
    t.boolean  "receive_admin_only",                          default: false
    t.boolean  "keep_msgid",                                  default: true
    t.boolean  "bounces_drop_all",                            default: false
    t.boolean  "bounces_notify_admins",                       default: true
    t.boolean  "include_list_headers",                        default: true
    t.boolean  "include_openpgp_header",                      default: true
    t.integer  "max_message_size_kb",                         default: 10240
    t.string   "language",                                    default: "en"
  end

  create_table "subscriptions", force: true do |t|
    t.integer  "list_id"
    t.string   "email"
    t.string   "fingerprint"
    t.boolean  "admin",             default: false
    t.boolean  "delivery_disabled", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["email", "list_id"], name: "index_subscriptions_on_email_and_list_id", unique: true
  add_index "subscriptions", ["list_id"], name: "index_subscriptions_on_list_id"

end
