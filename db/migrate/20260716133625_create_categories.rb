class CreateCategories < ActiveRecord::Migration[8.1]
  def up
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true
    add_index :categories, :position
    add_index :categories, :active

    add_check_constraint :categories,
                         "position >= 0",
                         name: "categories_position_non_negative"
  end

  def down
    drop_table :categories
  end
end
