require 'spec_helper'

describe Schleuder::KeyFetcher do

  context '#fetch' do
    it 'reports an error if both, vks_keyserver and sks_keyserver, are blank' do
      Conf.instance.config['vks_keyserver'] = ''
      Conf.instance.config['sks_keyserver'] = ''
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('98769E8A1091F36BD88403ECF71A3F8412D83889')

      expect(output).to eql('Error while fetching data from the internet: No keyserver configured, cannot query anything')

      Conf.instance.reload!
      teardown_list_and_mailer(list)
    end

    it 'fetches one key by fingerprint from SKS if vks_keyserver is blank' do
      resp = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/expired_key_extended.txt'))
      Typhoeus.stub(/search=98769E8A1091F36BD88403ECF71A3F8412D83889/).and_return(resp)
      Conf.instance.config['vks_keyserver'] = ''
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('98769E8A1091F36BD88403ECF71A3F8412D83889')

      expect(output).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]/)

      Conf.instance.reload!
      teardown_list_and_mailer(list)
    end

    it 'fetches one key by email from SKS if vks_keyserver is blank' do
      resp = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/expired_key_extended.txt'))
      Typhoeus.stub(/search=admin%40example.net/).and_return(resp)
      Conf.instance.config['vks_keyserver'] = ''
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('admin@example.net')

      expect(output).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]/)

      Conf.instance.reload!
      teardown_list_and_mailer(list)
    end

    it 'fetches one key by fingerprint from VKS if vks_keyserver is set' do
      resp = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/expired_key_extended.txt'))
      Typhoeus.stub(/by-fingerprint\/98769E8A1091F36BD88403ECF71A3F8412D83889/).and_return(resp)
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('98769E8A1091F36BD88403ECF71A3F8412D83889')

      expect(output).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]/)

      teardown_list_and_mailer(list)
    end

    it 'fetches one key by email from VKS if vks_keyserver is set' do
      resp = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/expired_key_extended.txt'))
      Typhoeus.stub(/by-email\/admin%40example.net/).and_return(resp)
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('admin@example.net')

      expect(output).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]/)

      teardown_list_and_mailer(list)
    end

    it 'fetches one key from a good URL' do
      resp = Typhoeus::Response.new(code: 200, body: File.read('spec/fixtures/expired_key_extended.txt'))
      Typhoeus.stub(/example.asc/).and_return(resp)
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('https://localhost/example.asc')

      expect(output).to match(/This key was fetched \(new key\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]/)

      teardown_list_and_mailer(list)
    end

    it "reports an error from trying to fetch an URL that doesn't exist" do
      resp = Typhoeus::Response.new(code: 404, body: 'Not Found')
      Typhoeus.stub(/something/).and_return(resp)
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('https://localhost/something')

      expect(output).to eql("Error: There's nothing at <https://localhost/something> (404 Not Found).")

      teardown_list_and_mailer(list)
    end

    it 'reports an error from trying to import non-key-material' do
      resp = Typhoeus::Response.new(code: 200, body: 'blabla')
      Typhoeus.stub(/example.asc/).and_return(resp)
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('https://localhost/example.asc')

      expect(output).to eql("Error while importing the fetched data: gpg: no valid OpenPGP data found.\n")

      teardown_list_and_mailer(list)
    end

    it 'reports the returned body content when receiving an unexpected HTTP status from the server' do
      resp = Typhoeus::Response.new(code: 503, body: 'Internal server error')
      Typhoeus.stub(/example.asc/).and_return(resp)
       
      list = create(:list)

      output = KeyFetcher.new(list).fetch('https://localhost/example.asc')

      expect(output).to eql('Error while fetching data from the internet: Internal server error')

      teardown_list_and_mailer(list)
    end
  end
end
