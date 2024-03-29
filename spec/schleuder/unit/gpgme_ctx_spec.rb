require 'spec_helper'

describe GPGME::Ctx do
  it '#keyimport' do
    list = create(:list)
    keymaterial = File.read('spec/fixtures/example_key.txt')

    expect(list.gpg.keys.map(&:fingerprint)).not_to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    expect {
      list.gpg.keyimport(keymaterial)
    }.to change{ list.gpg.keys.size }.by 1
    expect(list.gpg.keys.map(&:fingerprint)).to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
  end

  it '#keyimport with unusable data' do
    list = create(:list)
    keymaterial = 'blabla'

    expect(list.gpg.keys.map(&:fingerprint)).not_to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    expect {
      list.gpg.keyimport(keymaterial)
    }.to change{ list.gpg.keys.size }.by 0
    expect(list.gpg.keys.map(&:fingerprint)).not_to include('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
  end

  it '#find_keys with prefixed fingerprint' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('0x59C71FB38AEE22E091C78259D06350440F759BD3')

    expect(keys.size).to eql(1)
  end

  it '#find_keys with un-prefixed fingerprint' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('59C71FB38AEE22E091C78259D06350440F759BD3')

    expect(keys.size).to eql(1)
  end

  it '#find_keys with bracketed email-address' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('schleuder <schleuder@example.org>')

    expect(keys.size).to eql(1)
  end

  it '#find_keys with bracketed wrong email-address' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('blabla <blabla@example.org>')

    expect(keys.size).to eql(0)
  end

  it '#find_keys with un-bracketed email-address' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('schleuder@example.org')

    expect(keys.size).to eql(1)
  end

  it '#find_keys with un-bracketed wrong email-address' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('blabla@example.org')

    expect(keys.size).to eql(0)
  end

  it '#find_keys with correctly marked sub-string' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('@schleuder')

    expect(keys.size).to eql(2)
  end

  it '#find_keys with correctly marked narrower sub-string' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('@schleuder@')

    expect(keys.size).to eql(1)
  end

  it '#find_keys with un-marked sub-string' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys('schleuder')

    expect(keys.size).to eql(2)
  end

  it '#find_keys without argument' do
    list = create(:list)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    keys = list.gpg.find_keys()

    expect(keys.size).to eql(2)
  end

  it '#clean_and_classify_input with prefixed fingerprint' do
    list = create(:list)

    kind, input = list.gpg.clean_and_classify_input('0x59C71FB38AEE22E091C78259D06350440F759BD3')
    expect(kind).to eql(:fingerprint)
    expect(input).to eql('0x59C71FB38AEE22E091C78259D06350440F759BD3')
  end

  it '#clean_and_classify_input with un-prefixed fingerprint' do
    list = create(:list)

    kind, input = list.gpg.clean_and_classify_input('59C71FB38AEE22E091C78259D06350440F759BD3')
    expect(kind).to eql(:fingerprint)
    expect(input).to eql('0x59C71FB38AEE22E091C78259D06350440F759BD3')
  end

  it '#clean_and_classify_input with bracketed email-address' do
    list = create(:list)

    kind, input = list.gpg.clean_and_classify_input('bla <bla@foo>')
    expect(kind).to eql(:email)
    expect(input).to eql('<bla@foo>')
  end

  it '#clean_and_classify_input with un-bracketed email-address' do
    list = create(:list)

    kind, input = list.gpg.clean_and_classify_input('bla@foo')
    expect(kind).to eql(:email)
    expect(input).to eql('<bla@foo>')
  end

  it '#clean_and_classify_input with URL' do
    list = create(:list)

    kind, input = list.gpg.clean_and_classify_input('http://example.org/foo')
    expect(kind).to eql(:url)
    expect(input).to eql('http://example.org/foo')
  end

  it '#clean_and_classify_input with some string' do
    list = create(:list)

    kind, input = list.gpg.clean_and_classify_input('lala')
    expect(kind).to eql(nil)
    expect(input).to eql('lala')
  end

  it '#gpgcli returns correct data types' do
    list = create(:list)

    err, out, exitcode = list.gpg.class.gpgcli('--list-keys')
    expect(err.class).to eql(Array)
    expect(out.class).to eql(Array)
    expect(exitcode).to be_a(Numeric)
  end

  context '#keyserver_arg' do
    it 'returns keyserver-args if a keyserver is configured' do
      list = create(:list)

      keyserver_args = list.gpg.send(:keyserver_arg)

      expect(keyserver_args).to eql("--keyserver #{Conf.keyserver}")
    end

    it 'returns a blank string if the keyserver-option is set to a blank value' do
      oldval = Conf.instance.config['keyserver']
      Conf.instance.config['keyserver'] = ''
      list = create(:list)

      keyserver_args = list.gpg.send(:keyserver_arg)

      expect(keyserver_args).to eql('')

      Conf.instance.config['keyserver'] = oldval
    end
  end

  context '#refresh_keys' do
    it 'updates keys from the keyserver' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))
      list.import_key(File.read('spec/fixtures/olduid_key.txt'))

      res = ''
      with_sks_mock(list.listdir) do
        res = list.gpg.refresh_keys(list.keys)
      end
      expect(res).to include("This key was updated (new signatures):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]\n")
      expect(res).to include("This key was updated (new user-IDs and new signatures):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org 2017-03-25\n")
    end
    
    it 'reports errors from refreshing keys' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))

      res = list.gpg.refresh_keys(list.keys)

      # If using the "standard-resolver" and a not reachable keyserver, dirmngr
      # reports a different error message than with its internal resolver 🤦
      # --
      # As of 2022/04/16, gnupg 2.2.27-3 as shipped in Debian, reports 'unknown host'
      # and 'connection refused', which is different from what we see in our upstream CI.
      # Again, reasons are unclear.
      # Given this, relax the expected error message.
      expect(res).to match(/keyserver refresh failed:/)
    end

    it 'does not import non-self-signatures' do
      list = create(:list)
      list.delete_key('87E65ED2081AE3D16BE4F0A5EBDBE899251F2412')
      list.subscribe('admin@example.org', nil, true)
      list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))

      res = ''
      with_sks_mock(list.listdir) do
        res = list.gpg.refresh_keys(list.keys)
      end
      # GPGME apparently does not show signatures correctly in some cases, so we better use gpgcli.
      signature_output = list.gpg.class.gpgcli(['--list-sigs', '87E65ED2081AE3D16BE4F0A5EBDBE899251F2412'])[1].grep(/0F759BD3.*schleuder@example.org/)

      expect(res).to be_empty
      expect(signature_output).to be_empty
    end

  end
end
