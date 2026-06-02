require "rails_helper"

RSpec.describe Product, type: :model do
  it "is valid with the factory" do
    expect(build(:product)).to be_valid
  end

  it "requires a name" do
    expect(build(:product, name: nil)).not_to be_valid
  end

  it "rejects negative stock" do
    expect(build(:product, stock: -1)).not_to be_valid
  end

  describe ".search_by_name" do
    it "finds products by a partial name and skips non-matches" do
      tenant = create(:tenant)
      mug = create(:product, tenant: tenant, name: "Blue Ceramic Mug")
      create(:product, tenant: tenant, name: "Wooden Spoon")

      results = tenant.products.search_by_name("ceramic")

      expect(results).to include(mug)
      expect(results.map(&:name)).not_to include("Wooden Spoon")
    end
  end

  describe "#image" do
    let(:file) { Rails.root.join("spec/fixtures/files/sample_product.jpg") }

    def attach!(product)
      product.image.attach(io: File.open(file), filename: "sample_product.jpg", content_type: "image/jpeg")
    end

    it "can attach a photo" do
      product = create(:product)
      attach!(product)
      expect(product.image).to be_attached
    end

    it "exposes a :card thumbnail variant" do
      product = create(:product)
      attach!(product)
      expect { product.image.variant(:card) }.not_to raise_error
    end
  end

  describe "#sell!" do
    it "reduces stock" do
      product = create(:product, stock: 5)
      product.sell!(2)
      expect(product.reload.stock).to eq(3)
    end

    it "raises when there isn't enough stock" do
      product = create(:product, stock: 1)
      expect { product.sell!(2) }.to raise_error(Product::InsufficientStock)
      expect(product.reload.stock).to eq(1)
    end

    # The headline test: two buyers race for the last unit. The pessimistic lock
    # must let exactly one win and keep stock from going negative.
    it "does not oversell under concurrent buyers", :no_transaction do
      product = create(:product, stock: 1)

      results = Queue.new
      threads = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            # fresh instance per thread — don't share one AR object across threads
            Product.find(product.id).sell!(1)
            results << :sold
          rescue Product::InsufficientStock
            results << :sold_out
          end
        end
      end
      threads.each(&:join)

      expect(product.reload.stock).to eq(0)
      expect([ results.pop, results.pop ].sort).to eq(%i[sold sold_out])
    end
  end
end
