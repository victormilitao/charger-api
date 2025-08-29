class WebhookPaymentService
  attr_reader :debt_id, :paid_amount, :paid_by

  def initialize(params)
    @debt_id = params[:debtId]
    @paid_amount = params[:paidAmount]
    @paid_by = params[:paidBy]
  end

  def process
    return failure_response('Parâmetros inválidos', :bad_request) unless valid_params?
    
    debt = find_debt
    return failure_response('Dívida não encontrada', :not_found) unless debt
    
    return failure_response('Dívida já foi paga', :unprocessable_entity) if debt.status == 'paid'
    
    process_payment(debt)
    success_response('Pagamento registrado com sucesso')
  rescue => e
    failure_response("Erro ao processar pagamento: #{e.message}")
  end

  private

  def valid_params?
    debt_id.present? && 
    paid_amount.present? && 
    paid_by.present? &&
    paid_amount.to_f > 0
  end

  def find_debt
    Debt.find_by(debt_id: debt_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def process_payment(debt)
    debt.mark_as_paid!(
      paid_amount: paid_amount,
      paid_by: paid_by
    )
  end

  def success_response(message)
    { success: true, message: message, status: :ok }
  end

  def failure_response(error_message, status = :unprocessable_entity)
    { success: false, error: error_message, status: status }
  end
end
