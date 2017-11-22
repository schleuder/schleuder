require_relative 'api_daemon_spec_helper'

describe 'keys via api' do

  before :each do
    @list = List.last || create(:list)
  end

  context 'list' do
    it 'doesn\'t list keys without authorization' do
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 401
    end
    it 'does list keys with authorization' do
      authorize!
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end
  end
  context 'check' do
    it 'doesn\'t check keys without authorization' do
      get "/keys/check_keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 401
    end
    it 'does check keys with authorization' do
      @list.import_key(File.read("spec/fixtures/revoked_key.txt"))
      @list.import_key(File.read("spec/fixtures/signonly_key.txt"))
      @list.import_key(File.read("spec/fixtures/expired_key.txt"))
      authorize!
      get "/keys/check_keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 200
      result = JSON.parse(last_response.body)['result']
      expect(result).to include("This key is expired:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889")
      expect(result).to include("This key is revoked:\n0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")
      expect(result).to include("This key is not capable of encryption:\n0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")

      @list.delete_key('0x70B2CF29E01AD53E')
      @list.delete_key('0x098AC83A4C0028E9')
      @list.delete_key('0x70B2CF29E01AD53E')
    end
  end

  context 'export' do
    it 'doesn\'t export keys without authorization' do
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 401
    end
    it 'does list keys with authorization' do
      authorize!
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end
  end

  context 'import' do
    it 'doesn\'t import keys without authorization' do
      parameters = {'list_id' => @list.id, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      expect {
        post '/keys.json', parameters.to_json
        expect(last_response.status).to be 401
      }.to change{ @list.keys.length }.by 0
    end
    it 'does list keys with authorization' do
      authorize!
      parameters = {'list_id' => @list.id, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      expect {
        post '/keys.json', parameters.to_json
        expect(last_response.status).to be 200
      }.to change{ @list.keys.length }.by 1
      @list.delete_key('0xEBDBE899251F2412')
    end
  end

  context 'delete' do
    before(:each) do
      @list.import_key(File.read("spec/fixtures/bla_foo_key.txt"))
    end

    it 'doesn\'t delete keys without authorization' do
      expect {
        delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"
        expect(last_response.status).to be 401
      }.to change{ @list.keys.length }.by 0
      @list.delete_key('0xEBDBE899251F2412')
    end
    it 'does delete keys with authorization' do
      authorize!
      expect {
        delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"
        expect(last_response.status).to be 200
      }.to change{ @list.keys.length }.by(-1)
    end
  end
end
