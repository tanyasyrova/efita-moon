class ProductsController < ApplicationController
  def show
    @product = Product.publicly_visible
                      .preload(:category, product_images: { image_attachment: :blob })
                      .find_by!(slug: params[:slug])
  end
end
