require "test_helper"
require Rails.root.join("db/migrate/20261009090100_migrate_categories_to_wear_locations")

class MigrateCategoriesToWearLocationsTest < ActiveSupport::TestCase
  setup do
    ProductImage.find_each(&:destroy)
    ActiveStorage::Attachment.where(record_type: "ProductImage").delete_all
    Product.delete_all
    Category.delete_all
  end

  test "migrates old categories to wear locations without losing products or images" do
    chokers = create_category(name: "Чокеры", slug: "chokers", position: 1)
    necklaces = create_category(name: "Колье", slug: "necklaces", position: 2)
    earrings = create_category(name: "Серьги", slug: "earrings", position: 4)
    bracelets = create_category(name: "Браслеты", slug: "bracelets", position: 5)
    anklets = create_category(name: "Анклеты", slug: "anklets", position: 6, active: false)

    choker = create_product(category: chokers, slug: "migration-choker", published: true)
    necklace = create_product(category: necklaces, slug: "migration-necklace", published: false)
    earring = create_product(category: earrings, slug: "migration-earring", published: true)
    bracelet = create_product(category: bracelets, slug: "migration-bracelet", published: true)
    anklet = create_product(category: anklets, slug: "migration-anklet", published: false)
    product_image = create_product_image(product: choker)

    migrate!

    assert_equal "neck", choker.reload.category.slug
    assert_equal "neck", necklace.reload.category.slug
    assert_equal "ears", earring.reload.category.slug
    assert_equal "hands", bracelet.reload.category.slug
    assert_equal "ankles", anklet.reload.category.slug
    assert ProductImage.exists?(product_image.id)
    assert_equal choker.id, product_image.reload.product_id
    assert_equal false, necklace.reload.published?
    assert_equal false, anklet.reload.published?
    assert Category.find_by!(slug: "ankles").active?
    assert_equal "Чокеры · Колье · Сотуары", Category.find_by!(slug: "neck").subtitle
    assert_empty Category.where(slug: %w[chokers necklaces sautoirs earrings bracelets anklets])
  end

  test "migration stops when inactive old category contains published product" do
    anklets = create_category(name: "Анклеты", slug: "anklets", position: 6, active: false)
    anklet = create_product(category: anklets, slug: "blocked-anklet", published: true)

    error = assert_raises(ActiveRecord::MigrationError) { migrate! }

    assert_match "inactive old categories contain published products", error.message
    assert_match "anklets (1 published products)", error.message
    assert Category.exists?(anklets.id)
    assert_equal "anklets", anklet.reload.category.slug
    assert anklet.published?
    assert_not Category.exists?(slug: "ankles")
  end

  test "migration can be run repeatedly without duplicate categories" do
    create_category(name: "Чокеры", slug: "chokers", position: 1)
    create_product(category: Category.find_by!(slug: "chokers"), slug: "repeatable-choker")

    migrate!
    migrate!

    assert_equal 1, Category.where(slug: "neck").count
    assert_equal 5, Category.where(slug: %w[neck ears hands ankles bags]).count
    assert_equal "neck", Product.find_by!(slug: "repeatable-choker").category.slug
  end

  test "migration stops on conflicting target category" do
    create_category(name: "Неожиданная категория", slug: "neck", position: 0)

    error = assert_raises(ActiveRecord::MigrationError) { migrate! }

    assert_match "Category slug 'neck' already exists with unexpected name", error.message
  end

  private

  def migrate!
    MigrateCategoriesToWearLocations.new.up
  end

  def create_category(attributes)
    Category.create!({ active: true }.merge(attributes))
  end

  def create_product(attributes)
    Product.create!({
      title: "Товар #{SecureRandom.hex(4)}",
      description: "Украшение ручной работы.",
      price: 1200,
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
