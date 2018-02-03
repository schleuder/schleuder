module Schleuder
  class Account < ActiveRecord::Base
    PASSWORD_CHARS = [
      ("a".."z").to_a,
      ("A".."Z").to_a,
      (0..9).to_a,
      %w[! @ # $ % ^ & * ( ) _ - + = { [ } ] : ; < , > . ? /]
    ].flatten

    has_secure_password

    has_many :subscriptions, foreign_key: "email", primary_key: "email"
    has_many :lists, through: :subscriptions
    has_many :admin_lists, through: :subscriptions

    validates :email, presence: true, email: true, uniqueness: true, allow_nil: false
    validates :password, presence: true, allow_nil: false

    before_save { email.downcase! }


    def generate_password(length=10)
      PASSWORD_CHARS.shuffle.take(length).join
    end
  end
end
