require "spec_helper"

describe GPGME::Key do
  describe "#oneline" do
    it "displays the expected basic attributes" do
      list = create(:list)

      key = list.key

      expect(key.oneline).to eql("0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org 2016-12-06")
    end
      
    it "displays the expected attributes for an expiring key" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/expiring_key.txt"))

      key = list.key("421FBF7190640136788593CD9EE9BE5929CACC20")

      expect(key.oneline).to eql("0x421FBF7190640136788593CD9EE9BE5929CACC20 expiringkey@example.org 2017-08-03 [expires: 2037-07-29]")
    end

    it "displays the expected attributes for an expired key" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/expired_key.txt"))

      key = list.key("98769E8A1091F36BD88403ECF71A3F8412D83889")
      
      expect(key.oneline).to eql("0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2010-08-14]")
    end

    it "displays the expected attributes for a revoked key" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/revoked_key.txt"))

      key = list.key("7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")
      
      expect(key.oneline).to eql("0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9 paz@nadir.org 2008-09-20 [revoked]")
    end

    # gpgme.rb doesn't report missing encryption-capability properly yet.
    it "displays the expected attributes for a key that's not capable of encryption" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/signonly_key.txt"))

      key = list.key("B1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")
      
      expect(key.oneline).to eql("0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E signonly@example.org 2017-08-03 [not capable of encryption]")
    end
  end
end
