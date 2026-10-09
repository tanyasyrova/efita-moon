module ApplicationHelper
  PRODUCT_STATUS_LABELS = {
    "available" => "В наличии",
    "made_to_order" => "Доступен к заказу",
    "unavailable" => "Нет в наличии"
  }.freeze
  CATEGORY_IMAGE_PATHS = {
    "neck" => "categories/chokers.jpeg",
    "ears" => "categories/earrings.jpeg",
    "hands" => "categories/bracelets.jpeg"
  }.freeze

  def product_status_label(product_or_status)
    status = product_or_status.respond_to?(:status) ? product_or_status.status : product_or_status

    PRODUCT_STATUS_LABELS.fetch(status)
  end

  def product_status_options
    Product.statuses.keys.map { |status| [ product_status_label(status), status ] }
  end

  def product_price(product, precision: 2)
    number_to_currency(product.price, unit: "₽", precision: precision, delimiter: " ", separator: ",", format: "%n %u")
  end

  def asset_exists?(path)
    Rails.root.join("app/assets/images", path).exist?
  end

  def category_image_path(category)
    CATEGORY_IMAGE_PATHS[category.slug].presence&.then do |path|
      path if asset_exists?(path)
    end
  end
end
