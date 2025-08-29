require 'rails_helper'

RSpec.describe 'Api::V1::DebtsController', type: :request do
  let(:csv_content) do
    <<~CSV
      name,government_id,email,debt_amount,debt_due_date,debt_id,status
      João Silva,12345678901,joao@example.com,1000.50,2024-12-31,DEBT001,pending
      Maria Santos,98765432100,maria@example.com,2500.75,2024-11-30,DEBT002,pending
    CSV
  end

  let(:csv_file) do
    file = Tempfile.new(['debts', '.csv'])
    file.write(csv_content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/csv')
  end

  after do
    csv_file.close
    csv_file.unlink
  end

  describe 'POST /api/v1/debts/import_debts_csv' do
    let(:endpoint) { '/api/v1/debts/import_debts_csv' }

    context 'when file is provided' do
      it 'returns success response' do
        expect {
          post endpoint, params: { file: csv_file }
        }.to change { LoadDebtsJob.queue_adapter.enqueued_jobs.count }.by(1)

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('CSV importado com sucesso')
        expect(json_response['errors']).to eq([])
      end

      it 'enqueues the LoadDebtsJob' do
        expect {
          post endpoint, params: { file: csv_file }
        }.to have_enqueued_job(LoadDebtsJob)
      end
    end

    context 'when file is not provided' do
      it 'returns bad request error' do
        post endpoint

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Arquivo é obrigatório')
      end
    end

    context 'when service raises an error' do
      before do
        allow_any_instance_of(DebtsCsvImportService).to receive(:import).and_raise(
          StandardError.new('Erro no processamento')
        )
      end

      it 'returns unprocessable entity error' do
        post endpoint, params: { file: csv_file }

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Erro ao processar CSV: Erro no processamento')
      end
    end

    context 'when file is invalid' do
      let(:invalid_file) { nil }

      it 'handles nil file gracefully' do
        post endpoint, params: { file: invalid_file }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'POST /api/v1/debts/generate_invoices' do
    let(:endpoint) { '/api/v1/debts/generate_invoices' }

    context 'when there are pending debts' do
      let!(:pending_debt1) { create(:debt, status: 'pending', debt_due_date: 5.days.ago) }
      let!(:pending_debt2) { create(:debt, status: 'pending', debt_due_date: 10.days.ago) }
      let!(:paid_debt) { create(:debt, status: 'paid', debt_due_date: 5.days.ago) }

      it 'returns success response and enqueues SendRemindersJob' do
        expect {
          post endpoint
        }.to have_enqueued_job(SendRemindersJob).with([pending_debt1.id, pending_debt2.id])

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Cobrança iniciada!')
      end

      it 'only processes pending debts' do
        post endpoint

        expect(response).to have_http_status(:ok)
        
        expect(SendRemindersJob).to have_been_enqueued.with([pending_debt1.id, pending_debt2.id])
        expect(SendRemindersJob).not_to have_been_enqueued.with([paid_debt.id])
      end

      it 'enqueues the job asynchronously' do
        expect {
          post endpoint
        }.to have_enqueued_job(SendRemindersJob)
      end
    end

    context 'when there are no pending debts' do
      let!(:paid_debt1) { create(:debt, status: 'paid', debt_due_date: 5.days.ago) }
      let!(:paid_debt2) { create(:debt, status: 'paid', debt_due_date: 10.days.ago) }

      it 'returns success response with no pending debts message' do
        expect {
          post endpoint
        }.not_to have_enqueued_job(SendRemindersJob)

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Nenhuma dívida pendente encontrada')
      end

      it 'does not enqueue any jobs' do
        expect {
          post endpoint
        }.not_to change { SendRemindersJob.queue_adapter.enqueued_jobs.count }
      end
    end

    context 'when there are no debts at all' do
      it 'returns success response with no pending debts message' do
        expect {
          post endpoint
        }.not_to have_enqueued_job(SendRemindersJob)

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Nenhuma dívida pendente encontrada')
      end
    end

    context 'when SendRemindersJob raises an error' do
      let!(:pending_debt) { create(:debt, status: 'pending', debt_due_date: 5.days.ago) }

      before do
        allow(SendRemindersJob).to receive(:perform_later).and_raise(
          StandardError.new('Erro ao enfileirar job')
        )
      end

      it 'raises the error' do
        expect {
          post endpoint
        }.to raise_error(StandardError, 'Erro ao enfileirar job')
      end
    end
  end
end
