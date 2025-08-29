class ReminderMailer < ApplicationMailer
  def payment_reminder(debt)
    @debt = debt
    @days_overdue = (Date.current - debt.debt_due_date).to_i
    
    mail(
      to: debt.email,
      subject: "Lembrete de Pagamento - Dívida #{debt.debt_id}"
    )
  end
end
