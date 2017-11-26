require "spec_helper"

describe "throttling processes" do
  it "runs only the configured amount of processes" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

    5.times do |i|
      fork { Schleuder::Runner.new().run(mail, list.email) }
    end
    exit_stati = Process.waitall.map { |pid, status| status.exitstatus }
    puts exit_stati.inspect

    expect(exit_stati.count(0)).to eql(1)
    expect(exit_stati.count(127)).to eql(4)
  end
end
