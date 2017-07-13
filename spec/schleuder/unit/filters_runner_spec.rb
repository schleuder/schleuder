require "spec_helper"

module Schleuder::Filters
  def self.dummy(list,mail)
    nil
  end
  def self.stop(list,mail)
    nil
  end
end

describe Schleuder::Filters::Runner do
  let(:subject) do
    # setup the list with an admin that can be notified
    list = create(:list, send_encrypted_only: false)
    list.subscribe("schleuder@example.org", nil, true)
    Schleuder::Filters::Runner.new(list)
  end

  it { is_expected.to respond_to :run }

  context '#run' do
    it 'runs the filters' do
      mail = Mail.new
      expect(Schleuder::Filters).to receive(:dummy).once
      expect(Schleuder::Filters).to_not receive(:stop)
      expect(subject.run(mail,['dummy'])).to be_nil
    end

    it 'stops on a StandardError and returns error' do
      mail = Mail.new
      error = StandardError.new
      expect(Schleuder::Filters).to_not receive(:dummy)
      expect(Schleuder::Filters).to receive(:stop).once { error }
      expect(subject.run(mail,['stop','dummy'])).to eql(error)
      expect(Mail::TestMailer.deliveries.first).to be_nil
    end
    it 'stops on a StandardError and will notify admins' do
      mail = Mail.new
      error = StandardError.new
      subject.list.bounces_drop_all = true
      expect(Schleuder::Filters).to_not receive(:dummy)
      expect(Schleuder::Filters).to receive(:stop).once { error }
      expect(subject.run(mail,['stop','dummy'])).to be_nil
      expect(Mail::TestMailer.deliveries.first).to_not be_nil
    end
    it 'stops on a StandardError and will notify on headers match' do
      mail = Mail.new
      error = StandardError.new
      mail['X-SPAM-FLAG'] = 'TRUE'
      expect(Schleuder::Filters).to_not receive(:dummy)
      expect(Schleuder::Filters).to receive(:stop).once { error }
      expect(subject.run(mail,['stop','dummy'])).to be_nil
      expect(Mail::TestMailer.deliveries.first).to_not be_nil
    end
  end
end
