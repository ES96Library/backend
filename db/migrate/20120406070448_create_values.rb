class CreateValues < ActiveRecord::Migration
  def change
    create_table :values do |t|
      t.references :item
      t.references :property
      t.text :name

      t.timestamps
    end
    add_index :values, :item_id
    add_index :values, :property_id
  end
end
