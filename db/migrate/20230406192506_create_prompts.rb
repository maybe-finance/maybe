class CreatePrompts < ActiveRecord::Migration[7.1]
  def change
    create_table :prompts, id: :uuid do |t|
      t.string :content
      t.string :categories, array: true, default: []

      t.timestamps
    end
  end
end
