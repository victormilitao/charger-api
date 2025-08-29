class LoadDebtsJob < ApplicationJob
  queue_as :debts_import

  def perform(file_path)
    Rails.logger.info "Iniciando processamento do arquivo: #{file_path}"
    
    begin
      LoadDebtsService.new(file_path).load_debts
    rescue => e
      Rails.logger.error "Erro ao importar dívidas: #{e.message}"
      raise e
    end
  end
end