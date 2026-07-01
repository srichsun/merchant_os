require "rails_helper"

# The endpoint no longer runs the agent inline — it echoes the question with a
# placeholder and enqueues a job that streams the reply back over ActionCable.
# The agent itself is unit-tested in spec/services; the job in spec/jobs.
RSpec.describe "Storefront chat", type: :request do
  let(:store) { create(:tenant, name: "My Shop") }

  it "echoes the question with a placeholder and enqueues the reply job" do
    expect do
      post storefront_store_chat_path(store.slug),
           params: { message: "我的訂單到了嗎", conversation_id: "conv-1" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end.to have_enqueued_job(CustomerServiceReplyJob)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("我的訂單到了嗎", "查詢中")
  end

  it "does not enqueue a job for a blank message" do
    expect do
      post storefront_store_chat_path(store.slug),
           params: { message: "  ", conversation_id: "conv-1" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end.not_to have_enqueued_job(CustomerServiceReplyJob)
  end
end
