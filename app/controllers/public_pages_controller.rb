class PublicPagesController < ApplicationController
  def home
    @categories = Category.active.ordered
    @featured_product = Product.publicly_visible
                               .preload(:category, product_images: { image_attachment: :blob })
                               .newest_first
                               .first
  end

  def about
  end
end
