# frozen_string_literal: true

class AddSlackUidToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :slack_uid, :string
    add_index :users, :slack_uid, unique: true
  end
end
