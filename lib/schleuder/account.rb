module Schleuder
  class Account < ActiveRecord::Base
    has_secure_password

    has_many :subscriptions, foreign_key: "email", primary_key: "email"
    has_many :lists, through: :subscriptions
    has_many :admin_lists, through: :subscriptions
  end
end
