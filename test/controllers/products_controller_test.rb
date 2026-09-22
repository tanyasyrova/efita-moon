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

  test "show renders one main h1" do
    get product_path(products(:moonlight_choker).slug)

    assert_response :success
    assert_select "h1", 1
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
    assert_select ".product-info__detail-label", text: "Размер"
    assert_select ".product-info__detail-value", text: product.size
    assert_select ".product-info__detail-label", text: "Материалы"
    assert_select ".product-info__detail-value", text: product.materials
  end

  test "show does not render empty optional labels" do
    get product_path(products(:pearl_earrings).slug)

    assert_response :success
    assert_select ".product-info__detail-label", { text: "Материалы", count: 0 }
    assert_select ".product-info__detail-label", { text: "Размер", count: 0 }
    assert_select ".product-info__details", false
  end

  test "show does not render description section when description is blank" do
    product = products(:moonlight_choker)
    product.update_column(:description, "")

    get product_path(product.slug)

    assert_response :success
    assert_select ".product-info__description", false
  end

  test "show renders placeholder for product without images" do
    product = products(:moonlight_choker)

    get product_path(product.slug)

    assert_response :success
    assert_select ".product-gallery__placeholder", text: /Изображение скоро появится/
    assert_select ".product-gallery img", false
    assert_no_match "/rails/active_storage", response.body
    assert_match product.title, response.body
    assert_match "9,99 ₽", response.body
  end

  test "show renders main image without thumbnails for product with one image" do
    product = products(:moonlight_choker)
    create_product_image(product: product, filename: "test.jpg", content_type: "image/jpeg")

    get product_path(product.slug)

    assert_response :success
    assert_select ".product-gallery__main-image[alt=?]", "#{product.title} — фото 1"
    assert_select ".product-gallery__main-image[src*=?]", "test.jpg"
    assert_select ".product-gallery__thumbnails", false
    assert_select ".product-info__title", text: product.title
  end

  test "show renders thumbnails and stimulus attributes for product with multiple images" do
    product = products(:moonlight_choker)
    create_product_image(product: product, filename: "test.jpg", content_type: "image/jpeg", position: 0)
    create_product_image(product: product, filename: "test.png", content_type: "image/png", position: 1)
    create_product_image(product: product, filename: "test.webp", content_type: "image/webp", position: 2)

    get product_path(product.slug)

    assert_response :success
    assert_select ".product-gallery[data-controller=?]", "product-gallery"
    assert_select ".product-gallery__main-image[data-product-gallery-target=?]", "mainImage"
    assert_select ".product-gallery__thumbnail[type=?]", "button", count: 3
    assert_select ".product-gallery__thumbnail[data-action=?]", "product-gallery#select", count: 3
    assert_select ".product-gallery__thumbnail[aria-pressed=?]", "true", count: 1
    assert_select ".product-gallery__thumbnail[aria-pressed=?]", "false", count: 2
  end

  test "show uses primary image and ordered thumbnails" do
    product = products(:moonlight_choker)
    create_product_image(product: product, filename: "test.jpg", content_type: "image/jpeg", position: 2)
    create_product_image(product: product, filename: "test.png", content_type: "image/png", position: 0)
    create_product_image(product: product, filename: "test.webp", content_type: "image/webp", position: 1)

    get product_path(product.slug)

    assert_response :success
    assert_select ".product-gallery__main-image[src*=?]", "test.png"

    thumbnails = css_select(".product-gallery__thumbnail-image").map { |image| image["src"] }
    assert_includes thumbnails[0], "test.png"
    assert_includes thumbnails[1], "test.webp"
    assert_includes thumbnails[2], "test.jpg"
  end

  test "show keeps hidden products unavailable when images exist" do
    product = products(:quiet_shine_earrings)
    create_product_image(product: product, filename: "test.jpg", content_type: "image/jpeg")

    get product_path(product.slug)

    assert_response :not_found
  end

  private

  def create_product_image(product:, filename:, content_type:, position: 0)
    ProductImage.new(product: product, position: position).tap do |product_image|
      product_image.image.attach(
        io: file_fixture(filename).open,
        filename: filename,
        content_type: content_type
      )
      product_image.save!
    end
  end
end
