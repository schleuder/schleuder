module Schleuder
  class Account < ActiveRecord::Base
    PASSWORD_CHARS = [
      ("a".."z").to_a,
      ("A".."Z").to_a,
      (0..9).to_a,
      %w[! @ # $ % ^ & * ( ) _ - + = { [ } ] : ; < , > . ? /]
    ].flatten
    PASSWORD_LENGTH_RANGE = 10..12

    has_secure_password

    has_many :subscriptions, foreign_key: "email", primary_key: "email"
    has_many :lists, through: :subscriptions
    has_many :admin_lists, through: :subscriptions

    validates :email, presence: true, email: true, uniqueness: true, allow_nil: false
    validates :password, presence: true, allow_nil: false

    before_save { email.downcase! }

    def admin_list_subscriptions
      Subscription.where(list_id: admin_lists.pluck(:id))
    end

    def set_new_password!
      new_password = generate_password
      self.update!(password: new_password)
      new_password
    end

    def is_subscribed_to_list?(list)
      lists.where(email: list.email).exists?
    end

    def is_admin_of_list?(list)
      admin_lists.where(email: list.email).exists?
    end


    private


    def generate_password
      length = rand(PASSWORD_LENGTH_RANGE)
      PASSWORD_CHARS.shuffle.take(length).join
    end
  end
end
