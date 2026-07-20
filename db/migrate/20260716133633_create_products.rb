class CreateProducts < ActiveRecord::Migration[8.1]
  def up
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description, null: false
      t.string :size
      t.text :materials
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "available"
      t.boolean :published, null: false, default: false

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :status
    add_index :products, :published
    add_index :products, [ :category_id, :published ]

    add_check_constraint :products,
                         "price >= 0",
                         name: "products_price_non_negative"

    add_check_constraint :products,
                         "status IN ('available', 'unavailable')",
                         name: "products_status_allowed"
  end

  def down
    drop_table :products
  end
end
