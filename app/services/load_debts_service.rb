class LoadDebtsService
  require 'csv'
  require 'fileutils'

  def initialize(file_path)
    @file_path = file_path
    @imported_count = 0
    @errors = []
  end

  def load_debts
    process_csv_in_batches(@file_path)
  end

  private 

  def process_csv_in_batches(file_path)
    batch_size = 1000
    batch = []
    
    CSV.foreach(file_path, headers: true, encoding: 'UTF-8') do |row|
      begin
        debt_attributes = map_csv_row_to_debt_attributes(row)
        batch << debt_attributes
        
        if batch.size >= batch_size
          import_batch(batch)
          batch = []
        end
      rescue => e
        @errors << "Linha #{$.}: #{e.message}"
      end
    end
    
    import_batch(batch) if batch.any?

    Rails.logger.info "Importação concluída com #{@imported_count} dívidas importadas"
  end

  def import_batch(batch)
    return if batch.empty?
    
    Debt.transaction do
      batch.each do |attributes|
        debt = Debt.new(attributes)
        if debt.save
          @imported_count += 1
        else
          @errors << "Erro ao salvar dívida #{attributes[:debt_id]}: #{debt.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def map_csv_row_to_debt_attributes(row)
    {
      name: row['name'],
      government_id: row['governmentId'],
      email: row['email'],
      debt_amount: parse_decimal(row['debtAmount']),
      debt_due_date: parse_date(row['debtDueDate']),
      debt_id: row['debtId'],
      status: 'pending'
    }
  end

  def parse_decimal(value)
    return nil if value.blank?
    
    cleaned_value = value.to_s.gsub(/[^\d.]/, '')
    
    BigDecimal(cleaned_value)
  rescue ArgumentError
    raise ArgumentError, "Valor inválido para valor da dívida: #{value}"
  end

  def parse_date(value)
    return nil if value.blank?
    
    Date.parse(value.to_s)
  rescue ArgumentError
    raise ArgumentError, "Data inválida: #{value}"
  end
end