class ProductsController < ApplicationController
  before_action :set_product, only: %i[edit update destroy]

  # Pundit: make sure every action checks a policy (catches forgotten authorize)
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    # acts_as_tenant already limits this to the current store
    scope = policy_scope(Product)
    @products =
      if params[:q].present?
        scope.search_by_name(params[:q]) # ordered by match rank
      else
        scope.order(created_at: :desc)
      end
  end

  def new
    @product = authorize Product.new
  end

  def create
    @product = authorize Product.new(product_params)
    if @product.save
      redirect_to products_path, notice: "Product created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @product
  end

  def update
    authorize @product
    if @product.update(product_params)
      redirect_to products_path, notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product
    @product.destroy
    redirect_to products_path, notice: "Product deleted."
  end

  private

  # Scoped to the current store by acts_as_tenant, so a store can't reach
  # another store's product (raises RecordNotFound instead).
  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :price_cents, :stock)
  end
end
