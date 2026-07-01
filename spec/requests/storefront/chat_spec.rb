require "rails_helper"

# The agent itself is unit-tested in spec/services; here we only check the
# storefront endpoint wires the message into the agent and renders the reply.
# The agent is stubbed so no real LLM call is made.
RSpec.describe "Storefront chat", type: :request do
  let(:store) { create(:tenant, name: "My Shop") }

  it "renders the agent's reply as a turbo stream" do
    allow(CustomerServiceAgent).to receive(:new)
      .and_return(instance_double(CustomerServiceAgent, respond: "訂單 #1：狀態 已出貨"))

    post storefront_store_chat_path(store.slug),
         params: { message: "我的訂單到了嗎" },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("我的訂單到了嗎", "已出貨")
  end

  it "passes the customer message to the agent" do
    agent = instance_double(CustomerServiceAgent)
    allow(CustomerServiceAgent).to receive(:new).and_return(agent)
    expect(agent).to receive(:respond).with("庫存還有嗎").and_return("有的")

    post storefront_store_chat_path(store.slug),
         params: { message: "庫存還有嗎" },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end
end
