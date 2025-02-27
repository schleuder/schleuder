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

  it '#normalize_key_identifier with prefixed fingerprint' do
    list = create(:list)

    input = list.gpg.normalize_key_identifier('0x59C71FB38AEE22E091C78259D06350440F759BD3')
    expect(input).to eql('0x59C71FB38AEE22E091C78259D06350440F759BD3')
  end

  it '#normalize_key_identifier with un-prefixed fingerprint' do
    list = create(:list)

    input = list.gpg.normalize_key_identifier('59C71FB38AEE22E091C78259D06350440F759BD3')
    expect(input).to eql('0x59C71FB38AEE22E091C78259D06350440F759BD3')
  end

  it '#normalize_key_identifier with bracketed email-address' do
    list = create(:list)

    input = list.gpg.normalize_key_identifier('bla <bla@foo>')
    expect(input).to eql('<bla@foo>')
  end

  it '#normalize_key_identifier with un-bracketed email-address' do
    list = create(:list)

    input = list.gpg.normalize_key_identifier('bla@foo')
    expect(input).to eql('<bla@foo>')
  end

  it '#normalize_key_identifier with URL' do
    list = create(:list)

    input = list.gpg.normalize_key_identifier('http://example.org/foo')
    expect(input).to eql('http://example.org/foo')
  end

  it '#normalize_key_identifier with some string' do
    list = create(:list)

    input = list.gpg.normalize_key_identifier('lala')
    expect(input).to eql('lala')
  end

  it '#gpgcli returns correct data types' do
    list = create(:list)

    err, out, exitcode = list.gpg.class.gpgcli('--list-keys')
    expect(err.class).to eql(Array)
    expect(out.class).to eql(Array)
    expect(exitcode).to be_a(Numeric)
  end

end
