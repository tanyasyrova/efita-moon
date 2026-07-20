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

  def create_category(attributes = {})
    Category.create!({
      name: "Колье #{SecureRandom.hex(4)}",
      slug: "necklaces-#{SecureRandom.hex(4)}",
      position: 1,
      active: true
    }.merge(attributes))
  end
end
