require 'rails_helper'

RSpec.describe DebtsCsvImportService, type: :service do
  let(:csv_content) do
    <<~CSV
      name,government_id,email,debt_amount,debt_due_date,debt_id,status
      João Silva,12345678901,joao@example.com,1000.50,2024-12-31,DEBT001,pending
      Maria Santos,98765432100,maria@example.com,2500.75,2024-11-30,DEBT002,pending
    CSV
  end

  let(:temp_file) do
    file = Tempfile.new(['debts', '.csv'])
    file.write(csv_content)
    file.rewind
    file.path
    file
  end

  let(:service) { described_class.new(temp_file) }

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#initialize' do
    it 'initializes with a file' do
      expect(service.instance_variable_get(:@file)).to eq(temp_file)
      expect(service.instance_variable_get(:@errors)).to eq([])
    end
  end

  describe '#import' do
    let(:import_dir) { Rails.root.join('tmp', 'imports') }
    let(:saved_files) { Dir.glob(import_dir.join('*.csv')) }

    before do
      FileUtils.rm_rf(import_dir) if Dir.exist?(import_dir)
    end

    after do
      FileUtils.rm_rf(import_dir) if Dir.exist?(import_dir)
    end

    it 'saves the imported file with UUID' do
      result = service.import

      expect(result[:errors]).to eq([])
      expect(result[:saved_file_path]).to be_present
      expect(File.exist?(result[:saved_file_path])).to be true
      expect(File.basename(result[:saved_file_path])).to match(/debts_import_[a-f0-9-]{36}\.csv/)
    end

    it 'creates the imports directory if it does not exist' do
      expect(Dir.exist?(import_dir)).to be false
      
      service.import
      
      expect(Dir.exist?(import_dir)).to be true
    end

    it 'copies the file content correctly' do
      result = service.import
      saved_content = File.read(result[:saved_file_path])
      
      expect(saved_content).to eq(csv_content)
    end

    it 'logs the file path' do
      expect(Rails.logger).to receive(:info).with(/Arquivo CSV salvo em:/)
      
      service.import
    end
  end

  describe 'private methods' do
    describe '#save_imported_file' do
      it 'returns a file path string' do
        file_path = service.send(:save_imported_file)
        
        expect(file_path).to be_a(String)
        expect(file_path).to end_with('.csv')
      end
    end
  end
end
