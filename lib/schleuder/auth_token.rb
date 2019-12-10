module Schleuder
  class AuthToken < ActiveRecord::Base
    VALID_FOR_SECONDS = 900
    validates :email, presence: true, email: true

    def self.count_recent(email:, seconds: 120)
      where(email: email, created_at: (Time.now - seconds.to_i)..).count
    end

    def self.find_valid(value:, email:)
      where(value: value, email: email, created_at: (Time.now - VALID_FOR_SECONDS)..).first
    end

    def self.make!(email:)
      AuthToken.create!(email: email, value: SecureRandom.uuid)
    end

    def self.destroy_outdated
      where(created_at: ..(Time.now - VALID_FOR_SECONDS)).destroy_all
    end

    def valid_for_minutes
      AuthToken::VALID_FOR_SECONDS / 60
    end
  end
end
