require 'rails_helper'

RSpec.describe LoadDebtsService, type: :service do
  let(:csv_content) do
    <<~CSV
      name,governmentId,email,debtAmount,debtDueDate,debtId
      João Silva,12345678901,joao@example.com,1000.50,2024-12-31,DEBT001
      Maria Santos,98765432100,maria@example.com,2500.75,2024-11-30,DEBT002
      Pedro Costa,11122233344,pedro@example.com,500.00,2024-10-15,DEBT003
    CSV
  end

  let(:temp_file) do
    file = Tempfile.new(['debts', '.csv'])
    file.write(csv_content)
    file.rewind
    file
  end

  let(:service) { described_class.new(temp_file.path) }

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#initialize' do
    it 'initializes with file path and sets counters' do
      expect(service.instance_variable_get(:@file_path)).to eq(temp_file.path)
      expect(service.instance_variable_get(:@imported_count)).to eq(0)
    end
  end

  describe '#load_debts' do
    it 'processes the CSV file and imports debts' do
      expect {
        service.load_debts
      }.to change(Debt, :count).by(3)

      expect(service.instance_variable_get(:@imported_count)).to eq(3)
    end

    it 'creates debts with correct attributes' do
      service.load_debts

      debt1 = Debt.find_by(debt_id: 'DEBT001')
      expect(debt1).to have_attributes(
        name: 'João Silva',
        government_id: '12345678901',
        email: 'joao@example.com',
        debt_amount: BigDecimal('1000.50'),
        debt_due_date: Date.parse('2024-12-31'),
        status: 'pending'
      )

      debt2 = Debt.find_by(debt_id: 'DEBT002')
      expect(debt2).to have_attributes(
        name: 'Maria Santos',
        government_id: '98765432100',
        email: 'maria@example.com',
        debt_amount: BigDecimal('2500.75'),
        debt_due_date: Date.parse('2024-11-30'),
        status: 'pending'
      )
    end

    context 'with invalid CSV data' do
      let(:csv_content) do
        <<~CSV
          name,governmentId,email,debtAmount,debtDueDate,debtId
          João Silva,12345678901,joao@example.com,invalid_amount,2024-12-31,DEBT001
          Maria Santos,98765432100,maria@example.com,2500.75,invalid_date,DEBT002
        CSV
      end

      it 'handles parsing errors gracefully' do
        expect {
          service.load_debts
        }.not_to raise_error

        expect(Debt.count).to eq(0)
      end
    end

    context 'with empty CSV file' do
      let(:csv_content) { "name,governmentId,email,debtAmount,debtDueDate,debtId\n" }

      it 'handles empty file without errors' do
        expect {
          service.load_debts
        }.not_to raise_error

        expect(service.instance_variable_get(:@imported_count)).to eq(0)
      end
    end
  end

  describe 'private methods' do
    describe '#map_csv_row_to_debt_attributes' do
      let(:row) do
        CSV::Row.new(
          ['name', 'governmentId', 'email', 'debtAmount', 'debtDueDate', 'debtId'],
          ['João Silva', '12345678901', 'joao@example.com', '1000.50', '2024-12-31', 'DEBT001']
        )
      end

      it 'maps CSV row to debt attributes correctly' do
        attributes = service.send(:map_csv_row_to_debt_attributes, row)

        expect(attributes).to eq({
          name: 'João Silva',
          government_id: '12345678901',
          email: 'joao@example.com',
          debt_amount: BigDecimal('1000.50'),
          debt_due_date: Date.parse('2024-12-31'),
          debt_id: 'DEBT001',
          status: 'pending'
        })
      end
    end

    describe '#parse_decimal' do
      it 'parses valid decimal values' do
        expect(service.send(:parse_decimal, '1000.50')).to eq(BigDecimal('1000.50'))
        expect(service.send(:parse_decimal, '324.42')).to eq(BigDecimal('324.42'))
        expect(service.send(:parse_decimal, '1000')).to eq(BigDecimal('1000'))
      end

      it 'raises error for invalid values' do
        expect {
          service.send(:parse_decimal, 'abc')
        }.to raise_error(ArgumentError, 'Valor inválido para valor da dívida: abc')
      end
    end

    describe '#parse_date' do
      it 'parses valid date values' do
        expect(service.send(:parse_date, '2024-12-31')).to eq(Date.parse('2024-12-31'))
        expect(service.send(:parse_date, '31/12/2024')).to eq(Date.parse('2024-12-31'))
      end

      it 'raises error for invalid dates' do
        expect {
          service.send(:parse_date, 'invalid_date')
        }.to raise_error(ArgumentError, 'Data inválida: invalid_date')
      end
    end

    describe '#import_batch' do
      let(:valid_attributes) do
        {
          name: 'João Silva',
          government_id: '12345678901',
          email: 'joao@example.com',
          debt_amount: BigDecimal('1000.50'),
          debt_due_date: Date.parse('2024-12-31'),
          debt_id: 'DEBT001',
          status: 'pending'
        }
      end

      it 'imports valid batch successfully' do
        expect {
          service.send(:import_batch, [valid_attributes])
        }.to change(Debt, :count).by(1)

        expect(service.instance_variable_get(:@imported_count)).to eq(1)
      end

      it 'handles empty batch' do
        expect {
          service.send(:import_batch, [])
        }.not_to change(Debt, :count)

        expect(service.instance_variable_get(:@imported_count)).to eq(0)
      end

      it 'handles invalid attributes gracefully' do
        invalid_attributes = valid_attributes.merge(name: nil)

        expect {
          service.send(:import_batch, [invalid_attributes])
        }.not_to raise_error

        expect(Debt.count).to eq(0)
        expect(service.instance_variable_get(:@imported_count)).to eq(0)
      end

      it 'uses database transaction' do
        allow(Debt).to receive(:transaction).and_yield

        service.send(:import_batch, [valid_attributes])

        expect(Debt).to have_received(:transaction)
      end
    end
  end

  describe 'batch processing' do
    let(:large_csv_content) do
      header = "name,governmentId,email,debtAmount,debtDueDate,debtId\n"
      rows = (1..1500).map do |i|
        "User #{i},#{i.to_s.rjust(11, '0')},user#{i}@example.com,#{i * 100}.50,2024-12-31,DEBT#{i.to_s.rjust(3, '0')}"
      end.join("\n")
      header + rows
    end

    let(:large_temp_file) do
      file = Tempfile.new(['large_debts', '.csv'])
      file.write(large_csv_content)
      file.rewind
      file
    end

    let(:large_service) { described_class.new(large_temp_file.path) }

    after do
      large_temp_file.close
      large_temp_file.unlink
    end

    it 'processes large files in batches of 1000' do
      expect {
        large_service.load_debts
      }.to change(Debt, :count).by(1500)

      expect(large_service.instance_variable_get(:@imported_count)).to eq(1500)
    end
  end
end
