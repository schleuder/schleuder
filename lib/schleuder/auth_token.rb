class AuthToken < ActiveRecord::Base
  VALID_FOR_SECONDS = 900

  def self.valid?(value)
    where(conditions: [ 'value = ? AND created_at > ?', value, Time.now - VALID_FOR_SECONDS]).exists?
  end

  def self.delete_by_token(value)
    delete_all(value: value)
  end
end
