require 'spec_helper'

describe KeywordHandlers::Base do
  it '#new stores the called keyword as instance variable' do
    mail = Mail.new
    mail.list = create(:list)
    instance = KeywordHandlers::Base.new('something')

    expect(instance.instance_variable_get('@called_keyword')).to eql('something')
  end

  it '#execute stores mail as instance variable' do
    # Mock implementation of run() so we can call execute()
    class KeywordHandlers::Base; def run; end; end
    mail = Mail.new
    mail.list = create(:list)
    instance = KeywordHandlers::Base.new('something')
    instance.execute(mail)

    expect(instance.instance_variable_get('@mail')).to eql(mail)
    expect(instance.instance_variable_get('@list')).to eql(mail.list)
  end

  it 'provides methods to register keywords' do
    expect(KeywordHandlers::Base.methods).to include(:handles_list_keyword)
    expect(KeywordHandlers::Base.methods).to include(:handles_request_keyword)
  end
end
