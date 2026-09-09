require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "show opens published product from active category by slug" do
    product = products(:moonlight_choker)

    get product_path(product.slug)

    assert_response :success
    assert_equal "/products/moonlight-choker", product_path(product.slug)
    assert_select ".product-page"
    assert_select "h1", product.title
  end

  test "show returns not found for unknown slug" do
    get product_path("unknown-product")

    assert_response :not_found
  end

  test "show returns not found for unpublished product" do
    get product_path(products(:quiet_shine_earrings).slug)

    assert_response :not_found
  end

  test "show returns not found for product from inactive category" do
    get product_path(products(:hidden_anklet).slug)

    assert_response :not_found
  end

  test "show displays available status" do
    get product_path(products(:moonlight_choker).slug)

    assert_response :success
    assert_match "В наличии", response.body
    assert_select ".product-status"
  end

  test "show displays made to order status" do
    get product_path(products(:silver_moon_choker).slug)

    assert_response :success
    assert_match "Доступен к заказу", response.body
  end

  test "show displays unavailable status" do
    get product_path(products(:sold_out_choker).slug)

    assert_response :success
    assert_match "Нет в наличии", response.body
  end

  test "show displays product details and category link" do
    product = products(:moonlight_choker)

    get product_path(product.slug)

    assert_match product.title, response.body
    assert_match product.description, response.body
    assert_match "9,99 ₽", response.body
    assert_select "a[href=?]", catalog_category_path(product.category.slug), text: product.category.name
  end

  test "show does not render empty optional labels" do
    get product_path(products(:pearl_earrings).slug)

    assert_response :success
    assert_no_match "Материалы:", response.body
    assert_no_match "Размер:", response.body
  end
end
