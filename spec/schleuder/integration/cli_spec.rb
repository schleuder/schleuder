require 'spec_helper'

describe 'cli' do
  context '#refresh_keys' do
    it 'updates keys from the keyserver' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))
      list.import_key(File.read('spec/fixtures/olduid_key.txt'))

      with_sks_mock(list.listdir) do
        Cli.new.refresh_keys
        dirmngr_pid = `pgrep -a dirmngr | grep #{list.listdir}`.split(' ', 2).first
        expect(dirmngr_pid).to be_nil
      end
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }

      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 \[expired: 2017-01-20\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org 2017-03-25\n/)

      teardown_list_and_mailer(list)
    end
    it 'updates keys from the keyserver for only a specific list' do
      list1 = create(:list)
      list2 = create(:list)
      [list1, list2].each do |list|
        list.subscribe('admin@example.org', nil, true)
        list.import_key(File.read('spec/fixtures/expired_key.txt'))
        list.import_key(File.read('spec/fixtures/olduid_key.txt'))
      end

      with_sks_mock(list1.listdir) do
        Cli.new.refresh_keys list1.email
      end
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list1.admins.first.email] }

      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list1.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 \[expired: 2017-01-20\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org 2017-03-25\n/)

      teardown_list_and_mailer(list1)
      teardown_list_and_mailer(list2)
    end

    it 'reports errors from refreshing keys' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))

      Cli.new.refresh_keys
      mail = Mail::TestMailer.deliveries.find { |message| message.to == [list.admins.first.email] }

      expect(mail.first_plaintext_part.decoded).to include("Refreshing all keys from the keyring of list #{list.email} resulted in this")
      if GPGME::Ctx.sufficient_gpg_version?('2.1')
        expect(mail.first_plaintext_part.decoded).to include('keyserver refresh failed:')
      else
        # The wording differs slightly among versions.
        expect(mail.first_plaintext_part.decoded).to match(/gpgkeys: .* error .* connect/)
      end

      teardown_list_and_mailer(list)
    end

    it 'warns about file system permissions if it was run as root' do
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
      dbfile = Conf.database['database']
      tmp_filename = "#{dbfile}.tmp"
      File.rename(dbfile, tmp_filename)
      IO.write(dbfile, 'bla')
      
      _, _, exitcode = capture_output do
        Cli.new.install
      end

      expect(exitcode).to eql(1)
      File.rename(tmp_filename, dbfile)
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
