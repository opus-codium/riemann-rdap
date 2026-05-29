# frozen_string_literal: true

RSpec.describe Riemann::Tools::Rdap do
  let(:instance) { subject }

  describe "#check_domain" do
    before do
      allow(RDAP).to receive(:domain).with("example.com").and_return({
        "events" => [
          {"eventAction" => "expiration", "eventDate" => "2021-01-01T00:00:00Z"}
        ]
      })
      allow(DateTime).to receive(:now).and_return(DateTime.parse("2020-12-01T00:00:00Z"))
    end

    it "reports expiration" do
      allow(instance).to receive(:report_expiration)
      instance.check_domain("example.com")
      expect(instance).to have_received(:report_expiration).with("example.com", 31, "Domain example.com will expire in 31 days")
    end
  end

  describe "#expiration_state" do
    it "returns nil for nil" do
      expect(instance.expiration_state(nil)).to be_nil
    end

    it "returns critical for less than 7 days" do
      expect(instance.expiration_state(6)).to eq("critical")
    end

    it "returns warning for less than 30 days" do
      expect(instance.expiration_state(29)).to eq("warning")
    end

    it "returns ok for more than 30 days" do
      expect(instance.expiration_state(30)).to eq("ok")
    end
  end
end
