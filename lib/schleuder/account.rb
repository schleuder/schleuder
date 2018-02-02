module Schleuder
  class Account < ActiveRecord::Base
    has_many :subscriptions, foreign_key: "email"
  end
end
