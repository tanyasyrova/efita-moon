class ProductsController < ApplicationController
  def show
    @product = Product.publicly_visible.find_by!(slug: params[:slug])
  end
end
