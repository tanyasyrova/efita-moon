require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product" do
    assert build_product.valid?
  end

  test "requires category" do
    product = build_product(category: nil)

    assert_not product.valid?
    assert_includes product.errors[:category], "must exist"
  end

  test "requires title" do
    product = build_product(title: nil)

    assert_not product.valid?
    assert_includes product.errors[:title], "can't be blank"
  end

  test "requires slug" do
    product = build_product(slug: nil)

    assert_not product.valid?
    assert_includes product.errors[:slug], "can't be blank"
  end

  test "requires unique slug" do
    create_product(slug: "moonlight-necklace")
    product = build_product(slug: "moonlight-necklace")

    assert_not product.valid?
    assert_includes product.errors[:slug], "has already been taken"
  end

  test "allows valid slug" do
    assert build_product(slug: "moonlight-necklace-2026").valid?
  end

  test "rejects invalid slug" do
    invalid_slugs = [ "moonlight necklace", "Moonlight-necklace", "лунный-свет" ]

    invalid_slugs.each do |slug|
      product = build_product(slug: slug)

      assert_not product.valid?, "#{slug.inspect} should be invalid"
    end
  end

  test "requires description" do
    product = build_product(description: nil)

    assert_not product.valid?
    assert_includes product.errors[:description], "can't be blank"
  end

  test "requires price" do
    product = build_product(price: nil)

    assert_not product.valid?
    assert_includes product.errors[:price], "can't be blank"
  end

  test "price cannot be negative" do
    product = build_product(price: -1)

    assert_not product.valid?
    assert_includes product.errors[:price], "must be greater than or equal to 0"
  end

  test "price can be zero" do
    assert build_product(price: 0).valid?
  end

  test "allows available, made_to_order, and unavailable statuses" do
    assert build_product(status: "available").valid?
    assert build_product(status: "made_to_order").valid?
    assert build_product(status: "unavailable").valid?
  end

  test "rejects invalid status" do
    product = build_product(status: "archived")

    assert_not product.valid?
    assert_includes product.errors[:status], "is not included in the list"
  end

  test "published must be true or false" do
    assert build_product(published: true).valid?
    assert build_product(published: false).valid?

    product = build_product(published: nil)

    assert_not product.valid?
    assert_includes product.errors[:published], "is not included in the list"
  end

  test "size and materials can be blank" do
    assert build_product(size: nil, materials: nil).valid?
  end

  test "belongs to category" do
    category = create_category
    product = create_product(category: category)

    assert_equal category, product.category
  end

  test "published scope returns published products" do
    published_product = create_product(slug: "published-necklace", published: true)
    draft_product = create_product(slug: "draft-necklace", published: false)

    assert_includes Product.published, published_product
    assert_not_includes Product.published, draft_product
  end

  test "publicly_visible includes published products from active categories with any status" do
    active_category = create_category
    available_product = create_product(
      category: active_category,
      slug: "visible-available-necklace",
      status: "available",
      published: true
    )
    made_to_order_product = create_product(
      category: active_category,
      slug: "visible-made-to-order-necklace",
      status: "made_to_order",
      published: true
    )
    unavailable_product = create_product(
      category: active_category,
      slug: "visible-unavailable-necklace",
      status: "unavailable",
      published: true
    )

    assert_includes Product.publicly_visible, available_product
    assert_includes Product.publicly_visible, made_to_order_product
    assert_includes Product.publicly_visible, unavailable_product
  end

  test "publicly_visible excludes unpublished products and products from inactive categories" do
    active_category = create_category
    inactive_category = create_category(active: false)
    unpublished_product = create_product(
      category: active_category,
      slug: "hidden-draft-necklace",
      published: false
    )
    inactive_category_product = create_product(
      category: inactive_category,
      slug: "hidden-category-necklace",
      published: true
    )

    assert_not_includes Product.publicly_visible, unpublished_product
    assert_not_includes Product.publicly_visible, inactive_category_product
  end

  test "newest_first sorts by created_at descending and id descending" do
    older_product = create_product(slug: "older-necklace")
    newer_lower_id_product = create_product(slug: "newer-lower-id-necklace")
    newer_higher_id_product = create_product(slug: "newer-higher-id-necklace")
    older_product.update_columns(created_at: 2.days.ago, updated_at: 2.days.ago)
    newer_lower_id_product.update_columns(created_at: 1.day.ago, updated_at: 1.day.ago)
    newer_higher_id_product.update_columns(created_at: 1.day.ago, updated_at: 1.day.ago)

    ordered_products = Product.where(id: [
      older_product.id,
      newer_lower_id_product.id,
      newer_higher_id_product.id
    ]).newest_first

    assert_equal [ newer_higher_id_product, newer_lower_id_product, older_product ], ordered_products.to_a
  end

  test "status enum methods and scopes" do
    available_product = create_product(slug: "available-necklace", status: "available")
    made_to_order_product = create_product(slug: "made-to-order-necklace", status: "made_to_order")
    unavailable_product = create_product(slug: "unavailable-necklace", status: "unavailable")

    assert_predicate available_product, :available?
    assert_predicate made_to_order_product, :made_to_order?
    assert_predicate unavailable_product, :unavailable?
    assert_includes Product.available, available_product
    assert_not_includes Product.available, made_to_order_product
    assert_not_includes Product.available, unavailable_product
    assert_includes Product.made_to_order, made_to_order_product
    assert_not_includes Product.made_to_order, available_product
    assert_not_includes Product.made_to_order, unavailable_product
    assert_includes Product.unavailable, unavailable_product
    assert_not_includes Product.unavailable, available_product
    assert_not_includes Product.unavailable, made_to_order_product
  end

  test "has many product images" do
    product = create_product
    product_image = create_product_image(product: product)

    assert_includes product.product_images, product_image
  end

  test "destroying product destroys associated product images" do
    product = create_product
    product_image = create_product_image(product: product)

    product.destroy!

    assert_not ProductImage.exists?(product_image.id)
  end

  test "product images are ordered by position and id" do
    product = create_product
    third = create_product_image(product: product, position: 2)
    first = create_product_image(product: product, position: 0)
    second = create_product_image(product: product, position: 1)
    same_position_first = create_product_image(product: product, position: 3)
    same_position_second = create_product_image(product: product, position: 3)

    assert_equal [
      first,
      second,
      third,
      same_position_first,
      same_position_second
    ], product.product_images.reload.to_a
  end

  test "primary_image returns nil when product has no images" do
    product = create_product

    assert_nil product.primary_image
  end

  test "primary_image returns first product image by association ordering" do
    product = create_product
    create_product_image(product: product, position: 2)
    primary_image = create_product_image(product: product, position: 0)
    create_product_image(product: product, position: 1)

    assert_equal primary_image, product.primary_image
  end

  test "primary_image is deterministic when positions match" do
    product = create_product
    first_image = create_product_image(product: product, position: 0)
    create_product_image(product: product, position: 0)

    assert_equal first_image, product.primary_image
  end

  private

  def build_product(attributes = {})
    Product.new({
      category: create_category,
      title: "Лунный свет",
      slug: "moonlight-necklace",
      description: "Украшение ручной работы.",
      size: "45 см",
      materials: "Гематит, горный хрусталь",
      price: 2500,
      status: "available",
      published: true
    }.merge(attributes))
  end

  def create_product(attributes = {})
    build_product(attributes).tap(&:save!)
  end

  def create_product_image(attributes = {})
    filename = attributes.delete(:filename) || "test.jpg"
    content_type = attributes.delete(:content_type) || "image/jpeg"
    content = attributes.delete(:content) || "image data"
    product = attributes.delete(:product) || create_product

    ProductImage.new({
      product: product,
      position: 0
    }.merge(attributes)).tap do |product_image|
      product_image.image.attach(
        io: StringIO.new(content),
        filename: filename,
        content_type: content_type
      )
      product_image.save!
    end
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
