require 'spec_helper'

describe Schleuder::AuthToken do
  it 'defines VALID_FOR_SECONDS' do
    expect(AuthToken::VALID_FOR_SECONDS).to be_a(Integer)
    expect(AuthToken::VALID_FOR_SECONDS).to be > 0
  end

  describe 'valid_for_minutes' do
    it 'returns the validity time range in minutes' do
      result = AuthToken.make!(email: 'foo@localhost').valid_for_minutes
      expect(result).to eql(15)
    end
  end

  describe '#make!()' do
    it 'creates a token with a given email address, a created_at DateTime and a UUID' do
      Timecop.freeze do
        token = AuthToken.make!(email: 'foo@localhost')
        expect(token.email).to eq('foo@localhost')
        expect(token.created_at).to eq(Time.now)
        expect(token.value).to be_a String
        expect(token.value.length).to eql(36)
      end
    end

    it 'does not create a token with an invalid email address' do
      expect {
        AuthToken.make!(email: 'x')
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '.find_valid()' do
    it 'does return a token that was created lately enough' do
      token = nil
      Timecop.travel(Time.now - AuthToken::VALID_FOR_SECONDS + 10) do
        token = AuthToken.create!(email: 'foo@localhost')
      end
      Timecop.return

      found = AuthToken.find_valid(value: token.value, email: 'foo@localhost')
      expect(found).to be_a(AuthToken)
      expect(found.value).to eql(token.value)
    end

    it 'does not return a token that was created too early' do
      token = nil
      Timecop.travel(Time.now - AuthToken::VALID_FOR_SECONDS - 10) do
        token = AuthToken.create!(email: 'foo@localhost')
      end
      Timecop.return

      found = AuthToken.find_valid(value: token.value, email: 'foo@localhost')
      expect(found).to be nil
    end
  end
end
