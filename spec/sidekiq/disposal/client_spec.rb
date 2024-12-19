# frozen_string_literal: true

require "sidekiq"
require "sidekiq/disposal/client"

RSpec.describe Sidekiq::Disposal::Client, :with_test_redis do
  subject(:client) { described_class.new }

  let(:bad_job) do
    {
      "jid" => "abcdef1234567890",
      "bid" => "deadbeef420420",
      "class" => "TillyScratchesTheCouchJob"
    }
  end
  let(:bad_job2) do
    {
      "jid" => "babababa2468013579",
      "bid" => "eeeeeeee5647382910",
      "class" => "TillySwipesAtPassersByJob"
    }
  end
  let(:good_job) do
    {
      "jid" => "9876543210fedcba",
      "bid" => "aceace5555",
      "class" => "TillyLeavesAToyMouseAtMyDoorJob"
    }
  end

  describe "#mark" do
    it "can mark job to be killed by jid" do
      client.mark(:kill, :jid, bad_job["jid"])
      expect(client.kill_target?(bad_job)).to be_truthy
      expect(client.discard_target?(bad_job)).to be_falsey
      expect(client.kill_target?(good_job)).to be_falsey
    end

    it "can mark job to be killed by bid" do
      client.mark(:kill, :bid, bad_job["bid"])
      expect(client.kill_target?(bad_job)).to be_truthy
      expect(client.discard_target?(bad_job)).to be_falsey
      expect(client.kill_target?(good_job)).to be_falsey
    end

    it "can mark job to be killed by class" do
      client.mark(:kill, :class, bad_job["class"])
      expect(client.kill_target?(bad_job)).to be_truthy
      expect(client.discard_target?(bad_job)).to be_falsey
      expect(client.kill_target?(good_job)).to be_falsey
    end

    it "can mark job to be discarded by jid" do
      client.mark(:discard, :jid, bad_job["jid"])
      expect(client.discard_target?(bad_job)).to be_truthy
      expect(client.kill_target?(bad_job)).to be_falsey
      expect(client.discard_target?(good_job)).to be_falsey
    end

    it "can mark job to be discarded by bid" do
      client.mark(:discard, :bid, bad_job["bid"])
      expect(client.discard_target?(bad_job)).to be_truthy
      expect(client.kill_target?(bad_job)).to be_falsey
      expect(client.discard_target?(good_job)).to be_falsey
    end

    it "can mark job to be discarded by class" do
      client.mark(:discard, :class, bad_job["class"])
      expect(client.discard_target?(bad_job)).to be_truthy
      expect(client.kill_target?(bad_job)).to be_falsey
      expect(client.discard_target?(good_job)).to be_falsey
    end
  end

  describe "#unmark" do
    it "removes the specified marker" do
      client.mark(:kill, :jid, bad_job["jid"])
      client.mark(:kill, :jid, bad_job2["jid"])
      expect(client.kill_target?(bad_job)).to be_truthy
      expect(client.kill_target?(bad_job2)).to be_truthy
      client.unmark(:kill, :jid, bad_job["jid"])
      expect(client.kill_target?(bad_job)).to be_falsey
      expect(client.kill_target?(bad_job2)).to be_truthy
    end
  end

  describe "#unmark_all" do
    it "removes all specified markers" do
      client.mark(:kill, :jid, bad_job["jid"])
      client.mark(:kill, :jid, bad_job2["jid"])
      expect(client.kill_target?(bad_job)).to be_truthy
      expect(client.kill_target?(bad_job2)).to be_truthy
      client.unmark_all(:kill)
      expect(client.kill_target?(bad_job)).to be_falsey
      expect(client.kill_target?(bad_job2)).to be_falsey
    end
  end

  describe "#markers" do
    it "returns all markers added" do
      client.mark(:kill, :jid, bad_job["jid"])
      client.mark(:kill, :jid, bad_job["jid"]) # To demonstrate idempotence
      client.mark(:kill, :class, bad_job["class"])
      client.mark(:discard, :class, bad_job2["class"])
      expect(client.markers(:kill).length).to eq(2)
      expect(client.markers(:discard).length).to eq(1)
    end
  end
end
