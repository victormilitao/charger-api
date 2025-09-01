class SendRemindersJob < ApplicationJob
  queue_as :default

  def perform(debt_ids)
    Debt.where(id: debt_ids).in_batches(of: 1000) do |batch|
      batch.each do |debt|
        begin
          generate_invoice_for_debt(debt)
          send_reminder_email(debt)
        rescue => e
          Rails.logger.error "Erro ao enviar lembrete para dívida #{debt.id}: #{e.message}"
        end
      end
    end
  end

  private

  def generate_invoice_for_debt(debt)
    invoice_data = {
      debt_id: debt.debt_id,
      customer_name: debt.name,
      customer_email: debt.email,
      amount: debt.debt_amount,
      due_date: debt.debt_due_date,
      government_id: debt.government_id
    }

    Rails.logger.info "Gerando boleto para dívida #{debt.debt_id}: #{invoice_data}"
  end

  def send_reminder_email(debt)
    begin
      ReminderMailer.payment_reminder(debt).deliver_now
      Rails.logger.info "Email de lembrete enviado com sucesso para #{debt.email}"
    rescue => e
      Rails.logger.error "Erro ao enviar email de lembrete para #{debt.email}: #{e.message}"
      raise e
    end
  end
end
