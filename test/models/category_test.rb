require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category" do
    assert build_category.valid?
  end

  test "requires name" do
    category = build_category(name: nil)

    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    create_category(name: "Колье", slug: "necklaces")
    category = build_category(name: "Колье", slug: "other-necklaces")

    assert_not category.valid?
    assert_includes category.errors[:name], "has already been taken"
  end

  test "requires slug" do
    category = build_category(slug: nil)

    assert_not category.valid?
    assert_includes category.errors[:slug], "can't be blank"
  end

  test "requires unique slug" do
    create_category(name: "Колье", slug: "necklaces")
    category = build_category(name: "Другие колье", slug: "necklaces")

    assert_not category.valid?
    assert_includes category.errors[:slug], "has already been taken"
  end

  test "allows valid slug" do
    assert build_category(slug: "silver-necklaces-2026").valid?
  end

  test "rejects invalid slug" do
    invalid_slugs = [ "silver necklaces", "Silver-necklaces", "серебро" ]

    invalid_slugs.each do |slug|
      category = build_category(slug: slug)

      assert_not category.valid?, "#{slug.inspect} should be invalid"
    end
  end

  test "position cannot be negative" do
    category = build_category(position: -1)

    assert_not category.valid?
    assert_includes category.errors[:position], "must be greater than or equal to 0"
  end

  test "position must be an integer" do
    category = build_category(position: 1.5)

    assert_not category.valid?
    assert_includes category.errors[:position], "must be an integer"
  end

  test "active must be true or false" do
    assert build_category(active: true).valid?
    assert build_category(active: false).valid?

    category = build_category(active: nil)

    assert_not category.valid?
    assert_includes category.errors[:active], "is not included in the list"
  end

  test "active scope returns active categories" do
    active_category = create_category(name: "Колье", slug: "necklaces", active: true)
    inactive_category = create_category(name: "Браслеты", slug: "bracelets", active: false)

    assert_includes Category.active, active_category
    assert_not_includes Category.active, inactive_category
  end

  test "ordered scope sorts by position and name" do
    third = create_category(name: "Ярусные украшения", slug: "tiered-jewelry", position: 2)
    first = create_category(name: "Авторские браслеты", slug: "author-bracelets", position: 1)
    second = create_category(name: "Лаконичные колье", slug: "minimal-necklaces", position: 1)

    ordered_categories = Category.where(id: [ first.id, second.id, third.id ]).ordered

    assert_equal [ first, second, third ], ordered_categories.to_a
  end

  test "has many products" do
    category = create_category
    product = create_product(category: category)

    assert_includes category.products, product
  end

  test "cannot destroy category with products" do
    category = create_category
    create_product(category: category)

    assert_not category.destroy
    assert_includes category.errors[:base], "Cannot delete record because dependent products exist"
    assert Category.exists?(category.id)
  end

  private

  def build_category(attributes = {})
    Category.new({
      name: "Категория #{SecureRandom.hex(4)}",
      slug: "category-#{SecureRandom.hex(4)}",
      position: 1,
      active: true
    }.merge(attributes))
  end

  def create_category(attributes = {})
    build_category(attributes).tap(&:save!)
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
end
