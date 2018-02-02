require "helpers/api_daemon_spec_helper"

describe "keys via api" do
  before :each do
    @list = List.last || create(:list)
  end

  context "list" do
    it "doesn't list keys without authentication" do
      get "/keys.json?list_id=#{@list.id}"
      expect(last_response.status).to be 401
    end

    it "doesn't list keys authorized as unassociated account" do
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql("Not authorized")
    end

    it "does list keys authorized as subscriber" do
      subscription = create(:subscription, list_id: @list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end

    it "does list keys authorized as list-admin" do
      subscription = create(:subscription, list_id: @list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end

    it "does list keys authorized as api_superadmin" do
      authorize_as_api_superadmin!

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end
  end

  context "check" do
    it "doesn't check keys without authentication" do
      get "/keys/check_keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 401
    end

    it "doesn't check keys authorized as unassociated account" do
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys/check_keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql("Not authorized")
    end

    it "doesn't check keys authorized as subscriber" do
      subscription = create(:subscription, list_id: @list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys/check_keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql("Not authorized")
    end

    it "does check keys authorized as list-admin" do
      subscription = create(:subscription, list_id: @list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      @list.import_key(File.read("spec/fixtures/revoked_key.txt"))
      @list.import_key(File.read("spec/fixtures/signonly_key.txt"))
      @list.import_key(File.read("spec/fixtures/expired_key.txt"))

      get "/keys/check_keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      result = JSON.parse(last_response.body)["result"]
      expect(result).to include("This key is expired:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889")
      expect(result).to include("This key is revoked:\n0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")
      expect(result).to include("This key is not capable of encryption:\n0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")

      @list.delete_key("0x70B2CF29E01AD53E")
      @list.delete_key("0x098AC83A4C0028E9")
      @list.delete_key("0x70B2CF29E01AD53E")
    end

    it "does check keys authorized as api_superadmin" do
      @list.import_key(File.read("spec/fixtures/revoked_key.txt"))
      @list.import_key(File.read("spec/fixtures/signonly_key.txt"))
      @list.import_key(File.read("spec/fixtures/expired_key.txt"))
      authorize_as_api_superadmin!

      get "/keys/check_keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      result = JSON.parse(last_response.body)["result"]
      expect(result).to include("This key is expired:\n0x98769E8A1091F36BD88403ECF71A3F8412D83889")
      expect(result).to include("This key is revoked:\n0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")
      expect(result).to include("This key is not capable of encryption:\n0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")

      @list.delete_key("0x70B2CF29E01AD53E")
      @list.delete_key("0x098AC83A4C0028E9")
      @list.delete_key("0x70B2CF29E01AD53E")
    end
  end

  context "export" do
    it "doesn't export keys without authentication" do
      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 401
    end

    it "doesn't list keys authorized as unassociated account" do
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql("Not authorized")
    end

    it "does list keys authorized as subscriber" do
      subscription = create(:subscription, list_id: @list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end

    it "does list keys authorized as list-admin" do
      subscription = create(:subscription, list_id: @list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end

    it "does list keys authorized as api_superadmin" do
      authorize_as_api_superadmin!

      get "/keys.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
    end
  end

  context "import" do
    it "doesn't import keys without authentication" do
      parameters = {"list_id" => @list.id, "keymaterial" => File.read("spec/fixtures/bla_foo_key.txt")}
      expect {
        post "/keys.json", parameters.to_json
        expect(last_response.status).to be 401
      }.to change { @list.keys.length }.by 0
    end

    it "doesn't import keys authorized as unassociated account" do
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {"list_id" => @list.id, "keymaterial" => File.read("spec/fixtures/bla_foo_key.txt")}
      num_keys = @list.keys.size

      post "/keys.json", parameters.to_json

      expect(@list.reload.keys.size).to eql(num_keys)
      expect(last_response.status).to be 403
    end

    it "does import keys authorized as subscriber" do
      subscription = create(:subscription, list_id: @list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {"list_id" => @list.id, "keymaterial" => File.read("spec/fixtures/bla_foo_key.txt")}
      num_keys = @list.keys.length

      post "/keys.json", parameters.to_json

      expect(@list.reload.keys.length).to eql(num_keys + 1)
      expect(last_response.status).to be 200

      @list.delete_key("0xEBDBE899251F2412")
    end

    it "does import keys authorized as list-admin" do
      subscription = create(:subscription, list_id: @list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {"list_id" => @list.id, "keymaterial" => File.read("spec/fixtures/bla_foo_key.txt")}
      num_keys = @list.keys.length

      post "/keys.json", parameters.to_json

      expect(@list.reload.keys.length).to eql(num_keys + 1)
      expect(last_response.status).to be 200

      @list.delete_key("0xEBDBE899251F2412")
    end

    it "does import keys authorized as api_superadmin" do
      authorize_as_api_superadmin!
      parameters = {"list_id" => @list.id, "keymaterial" => File.read("spec/fixtures/bla_foo_key.txt")}
      num_keys = @list.keys.length

      post "/keys.json", parameters.to_json

      expect(@list.reload.keys.length).to eql(num_keys + 1)
      expect(last_response.status).to be 200

      @list.delete_key("0xEBDBE899251F2412")
    end

    it "returns json with key details about imported keys" do
      authorize!
      keymaterial = [File.read("spec/fixtures/expired_key.txt"), File.read("spec/fixtures/bla_foo_key.txt")].join("\n")
      parameters = {"list_id" => @list.id, "keymaterial" => keymaterial}
      post "/keys.json", parameters.to_json
      result = JSON.parse(last_response.body)

      expect(result).to be_a(Hash)
      keys = result["keys"]
      expect(keys).to be_a(Array)
      expect(keys.size).to eq(2)

      expect(keys[0]).to be_a(Hash)
      expect(keys[0]["import_action"]).to eq("imported")
      expect(keys[0]["fingerprint"]).to eq("98769E8A1091F36BD88403ECF71A3F8412D83889")
      expect(keys[0]["summary"]).to eq("0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2010-08-14]")

      expect(keys[1]).to be_a(Hash)
      expect(keys[1]["import_action"]).to eq("imported")
      expect(keys[1]["fingerprint"]).to eq("87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
      expect(keys[1]["summary"]).to eq("0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412 bla@foo 2010-03-14")

      @list.delete_key("0x98769E8A1091F36BD88403ECF71A3F8412D83889")
      @list.delete_key("0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end

    it "returns json with empty array in case of useless input" do
      authorize!
      parameters = {"list_id" => @list.id, "keymaterial" => "something something"}
      post "/keys.json", parameters.to_json
      result = JSON.parse(last_response.body)

      expect(result).to be_a(Hash)
      keys = result["keys"]
      expect(keys).to be_a(Array)
      expect(keys.size).to eq(0)
    end
  end

  context "delete" do
    before(:each) do
      @list.import_key(File.read("spec/fixtures/bla_foo_key.txt"))
    end

    it "doesn't delete keys without authentication" do
      num_keys = @list.keys.length

      delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"

      expect(last_response.status).to be 401
      expect(@list.reload.keys.length).to eql(num_keys)

      @list.delete_key("0xEBDBE899251F2412")
    end

    it "doesn't delete keys authorized as unassociated account" do
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      num_keys = @list.keys.length

      delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql("Not authorized")
      expect(@list.reload.keys.length).to eql(num_keys)
    end

    it "doesn't delete keys authorized as subscriber" do
      subscription = create(:subscription, list_id: @list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      num_keys = @list.keys.length

      delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql("Not authorized")
      expect(@list.reload.keys.length).to eql(num_keys)
    end

    it "does delete keys authorized as list-admin" do
      subscription = create(:subscription, list_id: @list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      num_keys = @list.keys.length

      delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(@list.reload.keys.length).to eql(num_keys - 1)
    end

    it "does delete keys authorized as api_superadmin" do
      authorize_as_api_superadmin!
      num_keys = @list.keys.length

      delete "/keys/0xEBDBE899251F2412.json?list_id=#{@list.id}"

      expect(last_response.status).to be 200
      expect(@list.reload.keys.length).to eql(num_keys - 1)
    end
  end

  context "a key with broken utf8 in uid" do
    context "already imported" do
      before(:each) do
        @list.import_key(File.read("spec/fixtures/broken_utf8_uid_key.txt"))
      end
      after(:each) do
        @list.delete_key("0x1242F6E13D8EBE4A")
      end
      it "does list this key" do
        authorize_as_api_superadmin!
        get "/keys.json?list_id=#{@list.id}"
        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body).length).to be 2
      end
      it "does get key" do
        authorize_as_api_superadmin!
        get "/keys/0x1242F6E13D8EBE4A.json?list_id=#{@list.id}"
        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body)["fingerprint"]).to eq("3102B29989BEE703AE5ED62E1242F6E13D8EBE4A")
      end
      it "does delete key" do
        authorize_as_api_superadmin!
        expect {
          delete "/keys/0x1242F6E13D8EBE4A.json?list_id=#{@list.id}"
          expect(last_response.status).to be 200
        }.to change { @list.keys.length }.by(-1)
      end
    end
    it "does add key" do
      authorize_as_api_superadmin!
      parameters = {"list_id" => @list.id, "keymaterial" => File.read("spec/fixtures/broken_utf8_uid_key.txt")}
      expect {
        post "/keys.json", parameters.to_json
        expect(last_response.status).to be 200
      }.to change { @list.keys.length }.by(1)
    end
  end
end
