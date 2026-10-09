require "test_helper"

class PublicPagesControllerTest < ActionDispatch::IntegrationTest
  test "root renders home page" do
    get root_path

    assert_response :success
    assert_select "h1", "свет."
    assert_select ".site-logo", "EFITA MOON"
  end

  test "root uses newest publicly visible product as featured product" do
    featured_product = create_product(title: "Новое украшение", slug: "new-featured-jewel")

    get root_path

    assert_response :success
    assert_match featured_product.title, response.body
    assert_select "a[href=?]", product_path(featured_product.slug), text: /Смотреть изделие/
  end

  test "root renders featured product image when product has image" do
    featured_product = create_product(title: "Украшение с фото", slug: "featured-with-image")
    create_product_image(product: featured_product)

    get root_path

    assert_response :success
    assert_select ".home-featured__media img[alt=?]", "#{featured_product.title} — фото 1"
    assert_select ".home-featured__media.image-placeholder", count: 0
  end

  test "root keeps featured product placeholder when product has no image" do
    featured_product = create_product(title: "Украшение без фото", slug: "featured-without-image")

    get root_path

    assert_response :success
    assert_match featured_product.title, response.body
    assert_select ".home-featured__media.image-placeholder", count: 1
    assert_select ".home-featured__media img", count: 0
  end

  test "about renders about page" do
    get about_path

    assert_response :success
    assert_select "h1", "EFITA MOON"
  end

  private

  def create_product(attributes = {})
    Product.create!({
      category: categories(:neck),
      title: "Украшение #{SecureRandom.hex(4)}",
      slug: "featured-product-#{SecureRandom.hex(4)}",
      description: "Украшение ручной работы.",
      materials: "Гематит, хрусталь",
      price: 2400,
      status: "available",
      published: true
    }.merge(attributes))
  end

  def create_product_image(product:)
    ProductImage.new(product: product, position: 0).tap do |product_image|
      product_image.image.attach(
        io: file_fixture("test.jpg").open,
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
      product_image.save!
    end
  end
end
