class UpdateProductsStatusConstraintForMadeToOrder < ActiveRecord::Migration[8.1]
  CONSTRAINT_NAME = "products_status_allowed"
  TWO_STATUS_CONSTRAINT = "status IN ('available', 'unavailable')"
  THREE_STATUS_CONSTRAINT = "status IN ('available', 'made_to_order', 'unavailable')"

  def up
    remove_check_constraint :products, name: CONSTRAINT_NAME
    add_check_constraint :products, THREE_STATUS_CONSTRAINT, name: CONSTRAINT_NAME
  end

  def down
    made_to_order_count = select_value(<<~SQL.squish)
      SELECT COUNT(*)
      FROM products
      WHERE status = 'made_to_order'
    SQL

    if made_to_order_count.to_i.positive?
      raise ActiveRecord::IrreversibleMigration,
            "Cannot restore two-status Product constraint while products with status 'made_to_order' exist. " \
            "Update or remove those records before rolling back."
    end

    remove_check_constraint :products, name: CONSTRAINT_NAME
    add_check_constraint :products, TWO_STATUS_CONSTRAINT, name: CONSTRAINT_NAME
  end
end
