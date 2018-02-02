require "spec_helper"

describe Schleuder::Account do
  it { is_expected.to respond_to :subscriptions }
end
