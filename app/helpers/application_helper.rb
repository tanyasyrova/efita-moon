module ApplicationHelper
  PRODUCT_STATUS_LABELS = {
    "available" => "В наличии",
    "made_to_order" => "Доступен к заказу",
    "unavailable" => "Нет в наличии"
  }.freeze

  def product_status_label(product_or_status)
    status = product_or_status.respond_to?(:status) ? product_or_status.status : product_or_status

    PRODUCT_STATUS_LABELS.fetch(status)
  end

  def product_status_options
    Product.statuses.keys.map { |status| [ product_status_label(status), status ] }
  end

  def product_price(product)
    number_to_currency(product.price, unit: "₽", precision: 2, delimiter: " ", separator: ",", format: "%n %u")
  end
end
