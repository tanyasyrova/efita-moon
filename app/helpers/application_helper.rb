module ApplicationHelper
  PRODUCT_STATUS_LABELS = {
    "available" => "В наличии",
    "made_to_order" => "Доступен к заказу",
    "unavailable" => "Нет в наличии"
  }.freeze

  def product_status_label(product)
    PRODUCT_STATUS_LABELS.fetch(product.status)
  end

  def product_price(product)
    number_to_currency(product.price, unit: "₽", precision: 2, delimiter: " ", separator: ",", format: "%n %u")
  end
end
