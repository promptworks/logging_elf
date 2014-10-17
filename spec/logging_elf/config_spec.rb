require 'spec_helper'

describe LoggingElf::Configuration do
  describe ".host" do
    it "sets the host name to the name of the current computer" do
      Socket.stub(gethostname: "logging_computer")
      expect(LoggingElf::Configuration.new.host).to eq("logging_computer")
    end
  end
end
