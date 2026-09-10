class CatalogController < ApplicationController
  def index
    @categories = Category.active.ordered
    @products = Product.publicly_visible
                       .newest_first
                       .includes(:category)
  end
end
