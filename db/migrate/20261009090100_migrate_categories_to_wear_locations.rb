class MigrateCategoriesToWearLocations < ActiveRecord::Migration[8.1]
  class MigrationCategory < ActiveRecord::Base
    self.table_name = "categories"
  end

  class MigrationProduct < ActiveRecord::Base
    self.table_name = "products"
  end

  TARGET_CATEGORIES = {
    "neck" => { name: "На шею", subtitle: "Чокеры · Колье · Сотуары", position: 0, active: true },
    "ears" => { name: "На уши", subtitle: "Серьги", position: 1, active: true },
    "hands" => { name: "На руки", subtitle: "Браслеты", position: 2, active: true },
    "ankles" => { name: "На ноги", subtitle: "Анклеты", position: 3, active: true },
    "bags" => { name: "На сумку", subtitle: "Обвесы · Подвески", position: 4, active: true }
  }.freeze

  OLD_TO_NEW_SLUGS = {
    "chokers" => "neck",
    "necklaces" => "neck",
    "sautoirs" => "neck",
    "earrings" => "ears",
    "bracelets" => "hands",
    "anklets" => "ankles"
  }.freeze

  def up
    MigrationCategory.reset_column_information
    MigrationProduct.reset_column_information

    transaction do
      validate_inactive_old_categories!
      validate_target_conflicts!
      targets = upsert_target_categories!
      move_products_to_targets!(targets)
      remove_empty_old_categories!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Category wear-location migration cannot be safely reversed without knowing the original product category split."
  end

  private

  def validate_inactive_old_categories!
    categories = MigrationCategory.where(slug: OLD_TO_NEW_SLUGS.keys, active: false)
    blocked_categories = categories.filter_map do |category|
      published_count = MigrationProduct.where(category_id: category.id, published: true).count
      next if published_count.zero?

      "#{category.slug} (#{published_count} published products)"
    end

    return if blocked_categories.empty?

    raise ActiveRecord::MigrationError,
          "Cannot migrate categories because inactive old categories contain published products: " \
          "#{blocked_categories.join(', ')}. Migrating them into active wear-location categories would make those " \
          "products publicly visible. Resolve publication or category visibility manually before running this migration."
  end

  def validate_target_conflicts!
    TARGET_CATEGORIES.each do |slug, attributes|
      category_by_slug = MigrationCategory.find_by(slug: slug)
      if category_by_slug.present? && category_by_slug.name != attributes.fetch(:name)
        raise ActiveRecord::MigrationError,
              "Category slug '#{slug}' already exists with unexpected name '#{category_by_slug.name}'."
      end

      category_by_name = MigrationCategory.find_by(name: attributes.fetch(:name))
      if category_by_name.present? && category_by_name.slug != slug
        raise ActiveRecord::MigrationError,
              "Category name '#{attributes.fetch(:name)}' already exists with unexpected slug '#{category_by_name.slug}'."
      end
    end
  end

  def upsert_target_categories!
    TARGET_CATEGORIES.each_with_object({}) do |(slug, attributes), categories|
      category = MigrationCategory.find_or_initialize_by(slug: slug)
      category.assign_attributes(attributes)
      category.save!
      categories[slug] = category
    end
  end

  def move_products_to_targets!(targets)
    OLD_TO_NEW_SLUGS.each do |old_slug, new_slug|
      old_category = MigrationCategory.find_by(slug: old_slug)
      next if old_category.blank?

      target_category = targets.fetch(new_slug)
      MigrationProduct.where(category_id: old_category.id).update_all(category_id: target_category.id)
    end
  end

  def remove_empty_old_categories!
    MigrationCategory.where(slug: OLD_TO_NEW_SLUGS.keys).find_each do |category|
      product_count = MigrationProduct.where(category_id: category.id).count
      if product_count.positive?
        raise ActiveRecord::MigrationError,
              "Cannot remove old category '#{category.slug}' because it still has #{product_count} products."
      end

      category.destroy!
    end
  end
end
