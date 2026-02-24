# frozen_string_literal: true

class ReplaceActiveStorageWithCarrierwave < ActiveRecord::Migration[8.1]
  def up
    add_column :receipts, :file, :string
  end

  def down
    remove_column :receipts, :file
  end
end
