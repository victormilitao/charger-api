class Debt < ApplicationRecord
  validates :name, presence: true
  validates :government_id, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :debt_amount, presence: true, numericality: { greater_than: 0 }
  validates :debt_due_date, presence: true
  validates :debt_id, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending paid] }

  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :overdue, -> { where('debt_due_date < ? AND status = ?', Date.current, 'pending') }

  def mark_as_paid!(paid_amount:, paid_by:)
    update!(
      status: 'paid',
      paid_amount: paid_amount,
      paid_by: paid_by,
      paid_at: Time.current
    )
  end
end