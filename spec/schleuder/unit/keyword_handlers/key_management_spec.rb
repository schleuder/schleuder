require 'spec_helper'

describe Schleuder::KeywordHandlers::AddKey do
  it 'registers keywords' do
    kw_list = KeywordHandlersRunner::REGISTERED_KEYWORDS.values.reduce(&:merge)
    
    expect(kw_list['add-key']).to eql(Schleuder::KeywordHandlers::AddKey)
    expect(kw_list['delete-key']).to eql(Schleuder::KeywordHandlers::DeleteKey)
    expect(kw_list['list-keys']).to eql(Schleuder::KeywordHandlers::ListKeys)
    expect(kw_list['get-key']).to eql(Schleuder::KeywordHandlers::GetKey)
    expect(kw_list['fetch-key']).to eql(Schleuder::KeywordHandlers::FetchKey)
  end

  context '.add_key' do
    it 'imports a key from inline material' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.body = File.read('spec/fixtures/example_key.txt')
      mail.to_s

      list_keys = mail.list.keys
      kw = KeywordHandlers::AddKey.new('add-key')
      kw.consume_arguments('')
      output = kw.execute(mail)

      expect(output).to eql("This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size + 1)
    end

    it 'imports a key from attached material' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.add_file('spec/fixtures/example_key.txt')
      mail.to_s

      list_keys = mail.list.keys
      kw = KeywordHandlers::AddKey.new('add-key')
      kw.consume_arguments('')
      output = kw.execute(mail)

      expect(output).to eql("This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size + 1)
    end

    it 'ignores body if an attachment is present' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.body = 'blabla'
      mail.add_file('spec/fixtures/example_key.txt')
      mail.to_s

      list_keys = mail.list.keys
      kw = KeywordHandlers::AddKey.new('add-key')
      kw.consume_arguments('')
      output = kw.execute(mail)

      expect(output).to eql("This key was newly added:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size + 1)
    end

    it 'ignores arguments' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.body = 'blabla'
      mail.to_s
      list_keys = mail.list.keys
      key_material = File.read('spec/fixtures/example_key.txt').lines

      kw = KeywordHandlers::AddKey.new('add-key')
      kw.consume_arguments(key_material)
      output = kw.execute(mail)

      expect(output).to eql('In the message you sent us, no keys could be found. :(')
      expect(mail.list.keys.size).to eql(list_keys.size)
    end

    it 'updates a key' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.body = 'blabla'
      mail.add_file('spec/fixtures/expired_key_extended.txt')
      mail.to_s
      mail.list.import_key(File.read('spec/fixtures/expired_key.txt'))
      list_keys = mail.list.keys

      kw = KeywordHandlers::AddKey.new('add-key')
      kw.consume_arguments('')
      output = kw.execute(mail)

      expect(output).to eql("This key was updated:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]\n")
      expect(mail.list.keys.size).to eql(list_keys.size)
    end

    it 'rejects garbage' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.body = 'blabla'
      mail.to_s
      list_keys = mail.list.keys

      kw = KeywordHandlers::AddKey.new('add-key')
      kw.consume_arguments('')
      output = kw.execute(mail)

      expect(output).to eql('In the message you sent us, no keys could be found. :(')
      expect(mail.list.keys.size).to eql(list_keys.size)
    end
  end

  context '.delete_key' do
    it 'deletes a key that distinctly matches the argument' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      kw = KeywordHandlers::DeleteKey.new('delete-key')
      kw.consume_arguments('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
      output = kw.execute(mail)

      expect(output).to eql("This key was deleted:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n")
      expect(mail.list.keys.size).to eql(list_keys.size - 1)
    end

    it 'deletes multiple keys that each distinctly match one argument' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.list.import_key(File.read('spec/fixtures/expired_key_extended.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      kw = KeywordHandlers::DeleteKey.new('delete-key')
      kw.consume_arguments('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE 98769E8A1091F36BD88403ECF71A3F8412D83889')
      output = kw.execute(mail)

      expect(output).to eql("This key was deleted:\n0xC4D60F8833789C7CAA44496FD3FFA6613AB10ECE schleuder2@example.org 2016-12-12\n\nThis key was deleted:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]\n")
      expect(mail.list.keys.size).to eql(list_keys.size - 2)
    end

    it 'deletes no key if the argument does not match' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.subscribe('subscription@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      kw = KeywordHandlers::DeleteKey.new('delete-key')
      kw.consume_arguments('0x0x0x')
      output = kw.execute(mail)

      expect(output).to eql("Error: No key found with this fingerprint: '0x0x0x'.")
      expect(mail.list.keys.size).to eql(list_keys.size)
    end

    it 'sends error message if no argument is given' do
      mail = Mail.new
      mail.list = create(:list)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.body = 'ignore me'
      mail.to_s
      list_keys = mail.list.keys

      kw = KeywordHandlers::DeleteKey.new('delete-key')
      kw.consume_arguments('')
      output = kw.execute(mail)

      expect(output).to eql("Error: You did not send any arguments for the keyword 'DELETE-KEY'.\n\nOne is required, more are optional, e.g.:\nX-DELETE-KEY: 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3\n\nOr, to delete multiple keys at once:\nX-DELETE-KEY: 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3 a-subscription@hostname\n\nThe matching keys will be deleted only if the argument matches them distinctly.\n")
      expect(mail.list.keys.size).to eql(list_keys.size)
    end
  end
end
