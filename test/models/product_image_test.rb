require "test_helper"

class ProductImageTest < ActiveSupport::TestCase
  test "valid product image with attached JPEG" do
    product_image = build_product_image

    assert product_image.valid?
  end

  test "belongs to product" do
    product = create_product
    product_image = create_product_image(product: product)

    assert_equal product, product_image.product
  end

  test "image must be attached" do
    product_image = ProductImage.new(product: create_product, position: 0)

    assert_not product_image.valid?
    assert_includes product_image.errors[:image], "must be attached"
  end

  test "position must be an integer" do
    product_image = build_product_image(position: 1.5)

    assert_not product_image.valid?
    assert_includes product_image.errors[:position], "must be an integer"
  end

  test "position cannot be negative" do
    product_image = build_product_image(position: -1)

    assert_not product_image.valid?
    assert_includes product_image.errors[:position], "must be greater than or equal to 0"
  end

  test "JPEG is allowed" do
    product_image = build_product_image_with_fixture("test.jpg", "image/jpeg")

    assert product_image.valid?
  end

  test "PNG is allowed" do
    product_image = build_product_image_with_fixture("test.png", "image/png")

    assert product_image.valid?
  end

  test "WebP is allowed" do
    product_image = build_product_image_with_fixture("test.webp", "image/webp")

    assert product_image.valid?
  end

  test "unsupported content type is rejected" do
    product_image = build_product_image(filename: "test.gif", content_type: "image/gif")

    assert_not product_image.valid?
    assert_includes product_image.errors[:image], "must be a JPEG, PNG, or WebP file"
  end

  test "file larger than 10 MB is rejected" do
    product_image = build_product_image(content: "x" * (10.megabytes + 1))

    assert_not product_image.valid?
    assert_includes product_image.errors[:image], "must be 10 MB or smaller"
  end

  test "has one attached image" do
    product_image = create_product_image

    assert product_image.image.attached?
  end

  private

  def build_product_image(attributes = {})
    filename = attributes.delete(:filename) || "test.jpg"
    content_type = attributes.delete(:content_type) || "image/jpeg"
    io = attributes.delete(:io) || StringIO.new(attributes.delete(:content) || "image data")
    product = attributes.delete(:product) || create_product

    ProductImage.new({
      product: product,
      position: 0
    }.merge(attributes)).tap do |product_image|
      product_image.image.attach(
        io: io,
        filename: filename,
        content_type: content_type
      )
    end
  end

  def build_product_image_with_fixture(filename, content_type)
    build_product_image(
      filename: filename,
      content_type: content_type,
      io: file_fixture(filename).open
    )
  end

  def create_product_image(attributes = {})
    build_product_image(attributes).tap do |product_image|
      product_image.save!
    end
  end

  def create_product(attributes = {})
    Product.create!({
      category: create_category,
      title: "Лунный свет",
      slug: "moonlight-necklace-#{SecureRandom.hex(4)}",
      description: "Украшение ручной работы.",
      price: 2500,
      status: "available",
      published: true
    }.merge(attributes))
  end

  def create_category(attributes = {})
    Category.create!({
      name: "Колье #{SecureRandom.hex(4)}",
      slug: "necklaces-#{SecureRandom.hex(4)}",
      position: 1,
      active: true
    }.merge(attributes))
  end
end
