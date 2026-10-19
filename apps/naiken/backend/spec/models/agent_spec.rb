require "rails_helper"

RSpec.describe Agent, type: :model do
  it "メールアドレスは大文字小文字を区別せず一意である" do
    create(:agent, email: "sato@example.com")
    agent = build(:agent, email: "SATO@example.com")

    expect(agent).to be_invalid
    expect(agent.errors[:email]).to include("はすでに存在します")
  end

  it "顧客を担当している場合は削除できない" do
    agent = create(:agent)
    create(:customer, agent:)

    expect(agent.destroy).to be false
    expect(agent.errors[:base]).to be_present
  end
end
