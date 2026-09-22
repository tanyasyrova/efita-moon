module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[ edit update destroy ]

    def index
      @categories = Category.ordered
                            .left_joins(:products)
                            .select("categories.*, COUNT(products.id) AS products_count")
                            .group("categories.id")
    end

    def new
      @category = Category.new(active: true, position: 0)
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        redirect_to admin_categories_path, notice: "Категория создана."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Категория обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.destroy
        redirect_to admin_categories_path, notice: "Категория удалена."
      else
        redirect_to admin_categories_path, alert: @category.errors.full_messages.to_sentence
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :slug, :position, :active)
    end
  end
end
