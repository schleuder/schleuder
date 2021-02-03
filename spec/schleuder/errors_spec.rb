require 'spec_helper'

describe 'Errors' do
  def signoff
    t('errors.signoff')
  end

  it '::MessageNotFromAdmin shows sensible string in response to to_s()' do
    expect(Errors::MessageNotFromAdmin.new.to_s).to eql(t('errors.message_not_from_admin'))
  end

  it '::MessageSenderNotSubscribed shows sensible string in response to to_s()' do
    expect(Errors::MessageSenderNotSubscribed.new.to_s).to eql(t('errors.message_sender_not_subscribed'))
  end

  it '::MessageUnauthenticated shows sensible string in response to to_s()' do
    expect(Errors::MessageUnauthenticated.new.to_s).to eql(t('errors.message_unauthenticated'))
  end

  it '::MessageUnencrypted shows sensible string in response to to_s()' do
    expect(Errors::MessageUnencrypted.new.to_s).to eql(t('errors.message_unencrypted'))
  end

  it '::MessageUnsigned shows sensible string in response to to_s()' do
    expect(Errors::MessageUnsigned.new.to_s).to eql(t('errors.message_unsigned'))
  end

  it '::LoadingListSettingsFailed shows sensible string in response to to_s()' do
    expect(Errors::LoadingListSettingsFailed.new.to_s).to eql(t('errors.loading_list_settings_failed', config_file: ENV['SCHLEUDER_LIST_DEFAULTS']))
  end

  it '::DecryptionFailed shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::DecryptionFailed.new(list).to_s).to eql(t('errors.decryption_failed', key: list.key.to_s, email: list.sendkey_address))
  end

  it '::KeyAdduidFailed shows sensible string in response to to_s()' do
    expect(Errors::KeyAdduidFailed.new('bla').to_s).to eql(t('errors.key_adduid_failed', errmsg: 'bla'))
  end

  it '::KeyGenerationFailed shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::KeyGenerationFailed.new(list.listdir, list.email).to_s).to eql(t('errors.key_generation_failed', listdir: list.listdir, listname: list.email))
  end

  it '::ListNotFound shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::ListNotFound.new(list.email).to_s).to eql(t('errors.list_not_found', email: list.email))
  end

  it '::ListdirProblem shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::ListdirProblem.new(list.listdir, 'not_empty').to_s).to eql(t('errors.listdir_problem.message', dir: list.listdir, problem: t('errors.listdir_problem.not_empty')))
  end

  it '::MessageEmpty shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::MessageEmpty.new(list).to_s).to eql(t('errors.message_empty', request_address: list.request_address))
  end

  it '::MessageTooBig shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::MessageTooBig.new(list).to_s).to eql(t('errors.message_too_big', allowed_size: list.max_message_size_kb))
  end

  it '::TooManyKeys shows sensible string in response to to_s()' do
    list = create(:list)
    expect(Errors::TooManyKeys.new(list.listdir, list.email).to_s).to eql(t('errors.too_many_keys', listdir: list.listdir, listname: list.email))
  end
end

