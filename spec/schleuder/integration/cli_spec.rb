require 'spec_helper'

describe 'cli' do
  context '#refresh_keys' do
    it 'updates keys from the keyserver' do
      resp1 = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/default_list_key.txt'))
      Typhoeus.stub(/by-fingerprint\/59C71FB38AEE22E091C78259D06350440F759BD3/).and_return(resp1)
      resp2 = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/expired_key_extended.txt'))
      Typhoeus.stub(/by-fingerprint\/98769E8A1091F36BD88403ECF71A3F8412D83889/).and_return(resp2)
      resp3 = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/olduid_key_with_newuid.txt'))
      Typhoeus.stub(/by-fingerprint\/6EE51D78FD0B33DE65CCF69D2104E20E20889F66/).and_return(resp3)

      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))
      list.import_key(File.read('spec/fixtures/olduid_key.txt'))

      Cli.new.refresh_keys
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }

      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 \[expired: 2017-01-20\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org 2017-03-25\n/)

      teardown_list_and_mailer(list)
    end

    it 'updates keys from the keyserver for only a specific list' do
      resp1 = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/default_list_key.txt'))
      Typhoeus.stub(/by-fingerprint\/59C71FB38AEE22E091C78259D06350440F759BD3/).and_return(resp1)
      resp2 = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/expired_key_extended.txt'))
      Typhoeus.stub(/by-fingerprint\/98769E8A1091F36BD88403ECF71A3F8412D83889/).and_return(resp2)
      resp3 = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/olduid_key_with_newuid.txt'))
      Typhoeus.stub(/by-fingerprint\/6EE51D78FD0B33DE65CCF69D2104E20E20889F66/).and_return(resp3)

      list1 = create(:list)
      list2 = create(:list)
      [list1, list2].each do |list|
        list.subscribe('admin@example.org', nil, true)
        list.import_key(File.read('spec/fixtures/expired_key.txt'))
        list.import_key(File.read('spec/fixtures/olduid_key.txt'))
      end

      Cli.new.refresh_keys list1.email
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list1.admins.first.email] }

      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list1.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 \[expired: 2017-01-20\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org 2017-03-25\n/)

      teardown_list_and_mailer(list1)
      teardown_list_and_mailer(list2)
    end

    it 'reports errors from refreshing keys' do
      resp1 = Typhoeus::Response.new(code: 404, body: 'Not Found')
      Typhoeus.stub(/by-fingerprint\/59C71FB38AEE22E091C78259D06350440F759BD3/).and_return(resp1)
      Typhoeus.stub(/search=59C71FB38AEE22E091C78259D06350440F759BD3/).and_return(resp1)
      resp2 = Typhoeus::Response.new(code: 503, body: 'Internal Server Error')
      Typhoeus.stub(/by-fingerprint\/98769E8A1091F36BD88403ECF71A3F8412D83889/).and_return(resp2)
      Typhoeus.stub(/search=98769E8A1091F36BD88403ECF71A3F8412D83889/).and_return(resp2)

      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))

      Cli.new.refresh_keys
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }

      expect(mail.first_plaintext_part.decoded).to include("Refreshing all keys from the keyring of list #{list.email} resulted in this")
      expect(mail.first_plaintext_part.decoded).to include("Error: No key could be found for '59C71FB38AEE22E091C78259D06350440F759BD3'.")
      expect(mail.first_plaintext_part.decoded).to include('Error while fetching data from the internet: Internal Server Error')

      teardown_list_and_mailer(list)
    end

    it 'warns about file system permissions if it was run as root' do
      resp = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/default_list_key.txt'))
      Typhoeus.stub(/by-fingerprint\/59C71FB38AEE22E091C78259D06350440F759BD3/).and_return(resp)

      expect(Process).to receive(:euid).and_return(0)
      list = create(:list)

      output, errors, exitcode = capture_output do
        Cli.new.refresh_keys(list.email)
      end

      expect(errors).to eql('')
      expect(exitcode).to be(nil)
      expect(output).to match(/^Warning: this process was run as root/)
    end
  end

  context '#install' do
    it 'exits if a shell-process failed' do
      # Rename the Rakefile instead of the DB-file, because changing the latter
      # caused spurious errors in other tests.
      File.rename('Rakefile', 'Rakefile.tmp')
      
      _, _, exitcode = capture_output do
        Cli.new.install
      end

      File.rename('Rakefile.tmp', 'Rakefile')
      expect(exitcode).to eql(1)
    end

    it 'warns about file system permissions if it was run as root' do
      expect(Process).to receive(:euid).and_return(0)

      output, errors, exitcode = capture_output do
        Cli.new.install
      end

      expect(errors).to eql('')
      expect(exitcode).to be(nil)
      expect(output).to match(/^Warning: this process was run as root/)
    end
  end

  context '#commands' do
    it 'exits with a status code of 1 in case the command is not implemented' do
      run_cli('not-implemented')

      expect($?.exitstatus).to eq(1)
    end
  end

  context '#check_keys' do
    it 'warns about file system permissions if it was run as root' do
      expect(Process).to receive(:euid).and_return(0)

      output, errors, exitcode = capture_output do
        Cli.new.check_keys
      end

      expect(output).to match(/^Warning: this process was run as root/)
    end
  end
end
