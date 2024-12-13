# frozen_string_literal: true

RSpec.describe Sidekiq::Disposal do
  it "has a version number" do
    expect(Sidekiq::Disposal::VERSION).not_to be nil
  end
end
