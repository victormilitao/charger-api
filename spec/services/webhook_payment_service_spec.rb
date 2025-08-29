require 'rails_helper'

RSpec.describe WebhookPaymentService do
  let(:debt) { create(:debt, status: 'pending') }
  let(:valid_params) do
    {
      debtId: debt.debt_id,
      paidAmount: 100.0,
      paidBy: 'John Doe'
    }
  end

  describe '#process' do
    context 'com parâmetros válidos' do
      it 'processa o pagamento com sucesso' do
        service = WebhookPaymentService.new(valid_params)
        result = service.process

        expect(result[:success]).to be true
        expect(result[:message]).to eq('Pagamento registrado com sucesso')
        expect(result[:status]).to eq(:ok)
        
        debt.reload
        expect(debt.status).to eq('paid')
        expect(debt.paid_amount).to eq(100.0)
        expect(debt.paid_by).to eq('John Doe')
        expect(debt.paid_at).to be_present
      end
    end

    context 'com parâmetros inválidos' do
      it 'retorna erro quando debtId está ausente' do
        params = valid_params.except(:debtId)
        service = WebhookPaymentService.new(params)
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Parâmetros inválidos')
        expect(result[:status]).to eq(:bad_request)
      end

      it 'retorna erro quando paidAmount está ausente' do
        params = valid_params.except(:paidAmount)
        service = WebhookPaymentService.new(params)
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Parâmetros inválidos')
        expect(result[:status]).to eq(:bad_request)
      end

      it 'retorna erro quando paidBy está ausente' do
        params = valid_params.except(:paidBy)
        service = WebhookPaymentService.new(params)
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Parâmetros inválidos')
        expect(result[:status]).to eq(:bad_request)
      end

      it 'retorna erro quando paidAmount é zero ou negativo' do
        params = valid_params.merge(paidAmount: 0)
        service = WebhookPaymentService.new(params)
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Parâmetros inválidos')
        expect(result[:status]).to eq(:bad_request)
      end
    end

    context 'quando a dívida não é encontrada' do
      it 'retorna erro de dívida não encontrada' do
        params = valid_params.merge(debtId: 'inexistente')
        service = WebhookPaymentService.new(params)
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Dívida não encontrada')
        expect(result[:status]).to eq(:not_found)
      end
    end

    context 'quando a dívida já foi paga' do
      let(:paid_debt) { create(:debt, status: 'paid') }
      let(:params) do
        {
          debtId: paid_debt.debt_id,
          paidAmount: 100.0,
          paidBy: 'John Doe'
        }
      end

      it 'retorna erro de dívida já paga' do
        service = WebhookPaymentService.new(params)
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Dívida já foi paga')
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end
  end
end
