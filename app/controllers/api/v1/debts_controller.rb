module Api
  module V1
    class DebtsController < ActionController::API

      def import_debts_csv
        @debts = Debt.all
        unless params[:file]
          return render json: { error: 'Arquivo é obrigatório' }, status: :bad_request
        end

        begin
          result = DebtsCsvImportService.new(params[:file]).import
          render json: { 
            message: 'CSV importado com sucesso',
            errors: result[:errors]
          }, 
          status: :ok
        rescue => e
          render json: { error: "Erro ao processar CSV: #{e.message}" }, status: :unprocessable_entity
        end
      end

      def generate_invoices
        pending_debts = Debt.pending
        if pending_debts.empty?
          return render json: { message: 'Nenhuma dívida pendente encontrada' }, status: :ok
        end

        SendRemindersJob.perform_later(pending_debts.pluck(:id))
        render json: { message: 'Cobrança iniciada!' }, status: :ok
      end

      def webhook_payment
        result = WebhookPaymentService.new(params).process
        
        if result[:success]
          render json: { message: result[:message] }, status: result[:status]
        else
          render json: { error: result[:error] }, status: result[:status]
        end
      end
    end
  end
end