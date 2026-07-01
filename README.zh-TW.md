# flashdrop

[English](README.md) · **中文**

用 Rails 打造的**網紅限時快閃平台**。創作者開店、綁定 Instagram，推出限時、限量的快閃商品（drop）。粉絲進到公開的商品頁——倒數計時、即時庫存、一鍵結帳——還有一個 **AI 客服助理直接回答商品問題**，讓網紅不用寫一堆文案、也不用泡在私訊裡。走 Kickstarter 那種急迫感、但不用進度條：時間到或庫存賣完，就沒了。

**線上 Demo**

| | |
|---|---|
| 專案介紹頁 | https://srichsun.github.io/flashdrop/ |
| 前台商店 | https://merchant-os.onrender.com/s/how-to-beast |
| 後台 | https://merchant-os.onrender.com（`owner@example.com` / `password123`）|

> 跑在 Render 免費方案——第一次開可能要等 ~30 秒喚醒。

**測試結帳**——兩個金流都是測試模式：

| 金流 | 測試卡號 | 備註 |
|------|----------|------|
| Stripe | `4242 4242 4242 4242` | 未來到期日 · 任意 CVC |
| ECPay（綠界）| `4311 9522 2222 2222` | CVC `222` · 未來到期日 · 3D 驗證碼會用真實簡訊寄出，輸入收到的碼 |

## 亮點

- **AI 客服 agent** —— 手刻的 LLM tool-use 迴圈（Anthropic Claude）。模型呼叫**租戶隔離**的工具查訂單狀態、即時庫存、退換貨政策，再在前台聊天框回覆。它**知道當前商品**（在商品頁問「這還有嗎」它就知道是哪一項）、跑在**背景 job**、並用 **Action Cable 把回覆即時推回**畫面（不卡）。**刻意設計成唯讀**——沒有工具能下單或退款——而且跨店隔離有測試背書（一家店永遠讀不到另一家的訂單）。迴圈上限與友善的錯誤 fallback，避免模型出錯或逾時把聊天卡住。
- **網紅身分** —— 每家店綁一個公開的 Instagram：帳號、藍勾勾、頭像。整個 header 點了跳到真的 IG 頁。
- **快閃商品頁** —— 一個商品一頁、沒有購物車。原價 vs 限量價（含折扣）、到開賣/結束的**即時倒數**、剩餘庫存、依狀態控制的搶購按鈕（即將開賣／熱賣中／已售完／已結束）。

## 功能

- **多租戶**商店，資料列層級隔離（`acts_as_tenant`）。
- **庫存防超賣** —— 結帳在悲觀鎖下扣庫存，有多執行緒的競態測試覆蓋。
- **訂單狀態機**（AASM）：`pending → paid → shipped`。
- **付款後的背景 job 鏈** —— 通知店家、寄信給買家、排入出貨。
- **可選金流結帳** —— Stripe 或 ECPay（綠界），都是簽章驗證的 webhook 確認；買家在結帳時輸入姓名、email、電話、收件地址。
- **交易信** —— 透過 Resend 的 HTTP API（訂單確認信）。
- **商品圖** —— Active Storage 存到 Tigris（S3 相容）物件儲存，前台有 Russian-doll 片段快取。
- **即時** —— AI 回覆與已付款訂單儀表板都走 Turbo Streams + Action Cable 串流。
- **JSON REST API**（`/api/v1`）—— JWT 驗證 + rack-attack 限流。
- **可觀測性** —— Sentry 錯誤追蹤 + Lograge 單行 JSON log。

## 架構重點

- **agent = LLM + 自己的工具 + 一個迴圈。** 工具就是讀「這家店」資料的 Ruby method，`acts_as_tenant` 幫每個查詢加上租戶範圍，所以 agent 天生安全。web request 只負責派工——模型迴圈在 request 執行緒外跑，跑完把答案推回瀏覽器。
- **兩種解析租戶的方式** —— 後台用登入的使用者；公開前台（和 agent）用網址裡的 store slug（`/s/:slug`）。
- **可插拔金流** —— 建 pending 訂單 → 導到選定金流 → 金流打 webhook → 驗簽章（Stripe 的 signature／ECPay 的 `CheckMacValue`）→ `order.pay!`。瀏覽器導回不被信任；只有驗證過的 webhook 才把訂單標記已付款。
- **Postgres 原生基礎設施** —— Solid Cache 和 Solid Cable 把快取與 Action Cable 放進 Postgres，免費方案不用 Redis。
- **快閃狀態用算的、不用存** —— `即將開賣/熱賣中/售完/結束` 是「時間 + 庫存」算出來的，不用排程去翻欄位。

## 技術取捨

| 面向 | 選擇 | 為何不用替代方案 |
|------|------|------------------|
| AI agent | Anthropic Claude + 手寫 tool-use 迴圈 | 完全掌控工具、租戶隔離、唯讀邊界；SDK 的高階 runner 把我想自己掌握的迴圈藏起來了 |
| Agent 延遲 | 背景 job + Action Cable 推送 | 同步呼叫 LLM 會卡住 web 執行緒好幾秒 |
| 多租戶 | `acts_as_tenant`（列層級）| schema-per-tenant 隨店家增加要一直加 schema migration |
| 訂單 | AASM 狀態機 | 明確、可測的狀態勝過手刻 `enum + if` |
| 快閃狀態 | 讀取時計算 | 存起來就得排程在準確的秒數翻欄位 |
| 防超賣 | 悲觀鎖 | 高競爭下最可靠；樂觀鎖會一直重試 |
| 金流 | Stripe + ECPay，可插拔 | 兩者共用同一套訂單/webhook 流程，買家結帳時選 |
| 寄信 | Resend HTTP API | 主機擋外送 SMTP |
| 圖片 | Active Storage + Tigris（S3）| 主機沒有物件儲存、磁碟是暫時性的 |
| 快取／即時 | Solid Cache + Solid Cable | 走 DB，免費方案不用 Redis |

## 技術棧

Rails 8 · PostgreSQL · **Anthropic Claude（AI agent）** · Hotwire · Devise · Pundit ·
acts_as_tenant · AASM · pg_search · Stripe · ECPay · Resend · Active Storage + Tigris ·
Solid Cache/Cable · JWT · Sentry + Lograge · RSpec · Docker · GitHub Actions · Render

## 工程

- **測試**：RSpec + FactoryBot；每個功能都連測試一起交付，含多執行緒的防超賣競態測試、以及 AI 工具的跨店隔離測試。
- **CI**（GitHub Actions）：RuboCop、RSpec、Brakeman、bundler-audit、gitleaks、Docker build。
- **可觀測性**：Sentry + Lograge，每行 log 都帶 `request_id` / `tenant_id` / `user_id`。

## 本機執行

需要 Ruby 3.4.x 和 PostgreSQL。AI 客服需要 `ANTHROPIC_API_KEY`。

```bash
bundle install
bin/rails db:prepare   # 建資料庫、載入 schema
bin/rails db:seed      # demo 資料：兩家網紅店，含快閃商品與訂單
export ANTHROPIC_API_KEY=sk-ant-...   # 客服 agent 用
bin/dev                # Rails + Tailwind，然後開 http://localhost:3000
```

跑測試：

```bash
bin/rspec
```

Demo 登入（密碼 `password123`）：`owner@example.com`、`staff@example.com`
（**How to Beast** · @howtobeast）、`owner2@example.com`（**Wisdm** · @wisdm）。

## 部署

用 `render.yaml` 部署在 Render（Docker web service + managed Postgres）。資料庫在啟動時自己 seed，所以 demo 一直有資料。在主機設 `RAILS_MASTER_KEY` 和 `ANTHROPIC_API_KEY`；金流、寄信、儲存的憑證都是環境變數（ECPay 會 fallback 到它的公開測試憑證）。
