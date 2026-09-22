module Admin
  class ProductsController < BaseController
    before_action :set_product, only: %i[ edit update destroy ]
    before_action :load_categories, only: %i[ new create edit update ]

    def index
      @products = Product.newest_first.includes(:category)
    end

    def new
      @product = Product.new(published: true, status: "available")
    end

    def create
      @product = Product.new(product_params)

      if save_product_with_images
        redirect_to edit_admin_product_path(@product), notice: "Товар создан."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      preload_product_images
    end

    def update
      if update_product_with_images
        redirect_to edit_admin_product_path(@product), notice: "Товар обновлён."
      else
        preload_product_images
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy

      redirect_to admin_products_path, notice: "Товар удалён."
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def load_categories
      @categories = Category.ordered
    end

    def product_params
      params.require(:product).permit(
        :title,
        :slug,
        :category_id,
        :description,
        :size,
        :materials,
        :price,
        :status,
        :published
      )
    end

    def uploaded_images
      params.fetch(:product, ActionController::Parameters.new)
            .permit(uploaded_images: [])[:uploaded_images]
            .to_a
            .reject(&:blank?)
    end

    def product_image_changes
      params.fetch(:product_images, ActionController::Parameters.new)
    end

    def save_product_with_images
      Product.transaction do
        @product.save!
        append_uploaded_images!
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      add_nested_error(e.record)
      false
    end

    def update_product_with_images
      Product.transaction do
        @product.update!(product_params)
        apply_product_image_changes!
        append_uploaded_images!
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      add_nested_error(e.record)
      false
    end

    def apply_product_image_changes!
      product_image_changes.each do |id, attributes|
        product_image = @product.product_images.find_by(id: id)
        next unless product_image

        permitted_attributes = attributes.permit(:position, :delete)

        if permitted_attributes[:delete] == "1"
          product_image.destroy!
        else
          product_image.update!(position: permitted_attributes[:position])
        end
      end
    end

    def append_uploaded_images!
      next_position = next_image_position

      uploaded_images.each do |upload|
        product_image = @product.product_images.build(position: next_position)
        product_image.image.attach(upload)
        product_image.save!
        next_position += 1
      end
    end

    def next_image_position
      max_position = @product.product_images.maximum(:position)
      max_position ? max_position + 1 : 0
    end

    def preload_product_images
      ActiveRecord::Associations::Preloader.new(
        records: @product.product_images.to_a,
        associations: { image_attachment: :blob }
      ).call
    end

    def add_nested_error(record)
      return if record == @product

      @product.errors.add(:base, record.errors.full_messages.to_sentence)
    end
  end
end
