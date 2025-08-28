class CreateDebts < ActiveRecord::Migration[5.2]
  def change
    create_table :debts do |t|
      t.string :name
      t.string :government_id
      t.string :email
      t.decimal :debt_amount
      t.decimal :debt_amount
      t.date :debt_due_date
      t.string :debt_id
      t.string :status
      t.datetime :paid_at
      t.decimal :paid_amount
      t.string :paid_by
    end
  end
end
