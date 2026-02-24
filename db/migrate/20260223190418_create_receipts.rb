# frozen_string_literal: true

class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code
      t.date :spent_on
      t.datetime :recorded_on

      t.timestamps
    end

    add_index :receipts, :spent_on
    add_index :receipts, :recorded_on
    add_index :receipts, :code
  end
end
