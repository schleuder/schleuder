require 'helpers/api_daemon_spec_helper'

describe 'keys via api' do
  context 'list' do
    it "doesn't list keys without authentication" do
      list = create(:list)

      get "/lists/#{list.email}/keys.json"

      expect(last_response.status).to be 401
    end

    it "doesn't list keys authorized as unassociated account" do
      list = create(:list)
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
    end

    it 'does list keys authorized as subscriber' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end

    it 'does list keys authorized as list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end

    it 'does list keys authorized as api_superadmin' do
      list = create(:list)
      authorize_as_api_superadmin!

      get "/lists/#{list.email}/keys.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end

    it 'contains the subscription email in the response authorized as list-admin' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      account = create(:account, email: 'schleuder@example.org')
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys.json"

      expect(JSON.parse(last_response.body).first['subscription']).to eq 'schleuder@example.org'
    end

    it 'does not contain the subscription key in the response json if user is authorized but no subscription exists' do
      list = create(:list)
      authorize_as_api_superadmin!

      get "/lists/#{list.email}/keys.json"

      expect(JSON.parse(last_response.body).first['subscription']).to eq nil
    end

    it 'does not contain the subscription email in the response if user is not an admin' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      account = create(:account, email: 'schleuder@example.org')
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys.json"
      
      expect(JSON.parse(last_response.body).first['subscription']).to eq nil
    end
  end

  context 'get key' do
    it 'contains the subscription email in the response authorized as list-admin' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      account = create(:account, email: 'schleuder@example.org')
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys/59C71FB38AEE22E091C78259D06350440F759BD3.json"

      expect(JSON.parse(last_response.body)['subscription']).to eq 'schleuder@example.org'
    end

    it 'does not contain the subscription key in the response json if user is authorized but no subscription exists' do
      list = create(:list)
      authorize_as_api_superadmin!

      get "/lists/#{list.email}/keys/59C71FB38AEE22E091C78259D06350440F759BD3.json"

      expect(JSON.parse(last_response.body)['subscription']).to eq nil
    end

    it 'does not contain the subscription email in the response if user is not an admin' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      account = create(:account, email: 'schleuder@example.org')
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys/59C71FB38AEE22E091C78259D06350440F759BD3.json"

      expect(JSON.parse(last_response.body)['subscription']).to eq nil
    end
  end

  context 'check' do
    it 'doesn\'t check keys without authentication' do
      list = create(:list)

      get "/lists/#{list.email}/keys/check.json"

      expect(last_response.status).to be 401
    end

    it "doesn't check keys authorized as unassociated account" do
      list = create(:list)
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys/check.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
    end

    it "doesn't check keys authorized as subscriber" do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/keys/check.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
    end

    it 'does check keys authorized as list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      list.import_key(File.read('spec/fixtures/revoked_key.txt'))
      list.import_key(File.read('spec/fixtures/signonly_key.txt'))
      list.import_key(File.read('spec/fixtures/expired_key.txt'))

      get "/lists/#{list.email}/keys/check.json"

      expect(last_response.status).to be 200
      result = JSON.parse(last_response.body)['result']
      expect(result).to include("This key is expired:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889")
      expect(result).to include("This key is revoked:\n0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")
      expect(result).to include("This key is not capable of encryption:\n0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")

      list.delete_key('0x70B2CF29E01AD53E')
      list.delete_key('0x098AC83A4C0028E9')
      list.delete_key('0x70B2CF29E01AD53E')
    end

    it 'does check keys authorized as api_superadmin' do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/revoked_key.txt'))
      list.import_key(File.read('spec/fixtures/signonly_key.txt'))
      list.import_key(File.read('spec/fixtures/expired_key.txt'))
      authorize_as_api_superadmin!

      get "/lists/#{list.email}/keys/check.json"

      expect(last_response.status).to be 200
      result = JSON.parse(last_response.body)['result']
      expect(result).to include("This key is expired:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889")
      expect(result).to include("This key is revoked:\n0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")
      expect(result).to include("This key is not capable of encryption:\n0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")

      list.delete_key('0x70B2CF29E01AD53E')
      list.delete_key('0x098AC83A4C0028E9')
      list.delete_key('0x70B2CF29E01AD53E')
    end
  end

  context 'import' do
    it "doesn't import keys without authentication" do
      list = create(:list)
      parameters = {'list_email' => list.email, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      expect {
        post "/lists/#{list.email}/keys.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to be 401
      }.to change{ list.keys.length }.by 0
    end

    it "doesn't import keys authorized as unassociated account" do
      list = create(:list)
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = { 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      num_keys = list.keys.size

      post "/lists/#{list.email}/keys.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(list.reload.keys.size).to eql(num_keys)
      expect(last_response.status).to be 403
    end

    it 'does import keys authorized as subscriber' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {'list_email' => list.email, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      num_keys = list.keys.length

      post "/lists/#{list.email}/keys.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(list.reload.keys.length).to eql(num_keys + 1)
      expect(last_response.status).to be 200

      list.delete_key('0xEBDBE899251F2412')
    end

    it 'does import keys authorized as list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {'list_email' => list.email, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      num_keys = list.keys.length

      post "/lists/#{list.email}/keys.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(list.reload.keys.length).to eql(num_keys + 1)
      expect(last_response.status).to be 200

      list.delete_key('0xEBDBE899251F2412')
    end

    it 'does import keys authorized as api_superadmin' do
      list = create(:list)
      authorize_as_api_superadmin!
      parameters = {'list_email' => list.email, 'keymaterial' => File.read('spec/fixtures/bla_foo_key.txt') }
      num_keys = list.keys.length

      post "/lists/#{list.email}/keys.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(list.reload.keys.length).to eql(num_keys + 1)
      expect(last_response.status).to be 200

      list.delete_key('0xEBDBE899251F2412')
    end
  end

  context 'delete' do
    it "doesn't delete keys without authentication" do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
      num_keys = list.keys.length

      delete "/lists/#{list.email}/keys/87E65ED2081AE3D16BE4F0A5EBDBE899251F2412.json"

      expect(last_response.status).to be 401
      expect(list.reload.keys.length).to eql(num_keys)

      list.delete_key('0xEBDBE899251F2412')
    end

    it "doesn't delete keys authorized as unassociated account" do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      num_keys = list.keys.length

      delete "/lists/#{list.email}/keys/87E65ED2081AE3D16BE4F0A5EBDBE899251F2412.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
      expect(list.reload.keys.length).to eql(num_keys)
    end

    it "doesn't delete keys authorized as subscriber" do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      num_keys = list.keys.length

      delete "/lists/#{list.email}/keys/87E65ED2081AE3D16BE4F0A5EBDBE899251F2412.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
      expect(list.reload.keys.length).to eql(num_keys)
    end

    it 'does delete keys authorized as list-admin' do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      num_keys = list.keys.length

      delete "/lists/#{list.email}/keys/87E65ED2081AE3D16BE4F0A5EBDBE899251F2412.json"

      expect(last_response.status).to be 200
      expect(list.reload.keys.length).to eql(num_keys - 1)
    end

    it 'does delete keys authorized as api_superadmin' do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/bla_foo_key.txt'))
      authorize_as_api_superadmin!
      num_keys = list.keys.length

      delete "/lists/#{list.email}/keys/87E65ED2081AE3D16BE4F0A5EBDBE899251F2412.json"

      expect(last_response.status).to be 200
      expect(list.reload.keys.length).to eql(num_keys - 1)
    end
  end

  context 'a key with broken utf8 in uid' do
    context 'already imported' do
      it 'does list this key' do
        list = create(:list)
        list.import_key(File.read('spec/fixtures/broken_utf8_uid_key.txt'))
        authorize_as_api_superadmin!

        get "/lists/#{list.email}/keys.json"

        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body).length).to be 2

        list.delete_key('0x1242F6E13D8EBE4A')
      end

      it 'does get key' do
        list = create(:list)
        list.import_key(File.read('spec/fixtures/broken_utf8_uid_key.txt'))
        authorize_as_api_superadmin!

        get "/lists/#{list.email}/keys/3102B29989BEE703AE5ED62E1242F6E13D8EBE4A.json"

        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body)['fingerprint']).to eq('3102B29989BEE703AE5ED62E1242F6E13D8EBE4A')

        list.delete_key('0x1242F6E13D8EBE4A')
      end

      it 'does delete key' do
        list = create(:list)
        list.import_key(File.read('spec/fixtures/broken_utf8_uid_key.txt'))
        authorize_as_api_superadmin!

        expect {
          delete "/lists/#{list.email}/keys/3102B29989BEE703AE5ED62E1242F6E13D8EBE4A.json"
          expect(last_response.status).to be 200
        }.to change{ list.keys.length }.by(-1)

        list.delete_key('0x1242F6E13D8EBE4A')
      end
    end

    it 'does add key' do
      list = create(:list)
      authorize_as_api_superadmin!
      parameters = {'list_email' => list.email, 'keymaterial' => File.read('spec/fixtures/broken_utf8_uid_key.txt') }

      expect {
        post "/lists/#{list.email}/keys.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to be 200
      }.to change{ list.keys.length }.by(1)

      list.delete_key('0x1242F6E13D8EBE4A')
    end
  end
end
