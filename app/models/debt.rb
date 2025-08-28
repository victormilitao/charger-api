class Debt < ApplicationRecord
  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :overdue, -> { where('debt_due_date < ? AND status = ?', Date.current, 'pending') }
end