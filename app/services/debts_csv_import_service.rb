class DebtsCsvImportService
  require 'csv'
  require 'fileutils'

  def initialize(file)
    @file = file
    @errors = []
  end

  def import
    saved_file_path = save_imported_file
    
    { errors: @errors, saved_file_path: saved_file_path }
  end

  private

  def save_imported_file
    import_dir = Rails.root.join('tmp', 'imports')
    FileUtils.mkdir_p(import_dir) unless Dir.exist?(import_dir)
    
    uuid = SecureRandom.uuid
    filename = "debts_import_#{uuid}.csv"
    file_path = import_dir.join(filename)
    
    FileUtils.cp(@file.path, file_path)
    
    Rails.logger.info "Arquivo CSV salvo em: #{file_path}"
    
    file_path.to_s
  end

end
