module Schleuder
  class Account < ActiveRecord::Base
    has_many :subscriptions, foreign_key: "email"
    has_many :lists, through: :subscriptions
    has_many :admin_lists, through: :subscriptions
  end
end
