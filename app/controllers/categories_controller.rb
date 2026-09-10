class CategoriesController < ApplicationController
  def show
    @category = Category.active.find_by!(slug: params[:slug])
    @products = @category.products
                         .published
                         .newest_first
  end
end
