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
        post endpoint, params: { file: csv_file }

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('CSV importado com sucesso')
        expect(json_response['errors']).to eq([])
      end

      it 'calls the import service' do
        expect_any_instance_of(DebtsCsvImportService).to receive(:import).and_return(
          { errors: [], saved_file_path: '/tmp/test.csv' }
        )

        post endpoint, params: { file: csv_file }
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
end
