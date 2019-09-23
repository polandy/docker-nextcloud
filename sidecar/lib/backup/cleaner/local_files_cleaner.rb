require 'fileutils'

class LocalFilesCleaner

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.progname = self.class.name
  end

  def cleanup(backups_to_keep, backup_dir_path)
    delete_unexpected_directories_in_backup_path(backup_dir_path)

    backup_files = Dir["#{backup_dir_path}/*"].sort_by{ |name| [name[/\d+/].to_i, name] }
    @logger.debug "Number of backups in #{backup_dir_path} is #{backup_files.length} (of max. #{backups_to_keep})"
    if backup_files.length > backups_to_keep
      files_to_delete = backup_files[0, backup_files.length - backups_to_keep]
      backups_to_keep = backup_files - files_to_delete
      @logger.info "Going do delete #{files_to_delete.length} files #{files_to_delete.join(', ')}. Keep #{backups_to_keep.length} backup files."
      @logger.debug "The following #{backups_to_keep.length} backups remain: #{backups_to_keep.join(', ')}"
      files_to_delete.each do |file|
        File.delete(file)
      end
    else
      @logger.info "Nothing to clean up."
    end
  end

  private

  def delete_unexpected_directories_in_backup_path(backup_dir_path)
    directories_to_delete = Dir.entries(backup_dir_path).select {|entry| File.directory? File.join(backup_dir_path, entry) and !(entry == '.' || entry == '..')}
    @logger.warn "#{backup_dir_path} should only contain tar.gz files. Going to delete directories #{backup_dir_path}/[#{directories_to_delete.join(', ')}]"
    directories_to_delete.each do |dir|
      FileUtils.rm_rf("#{backup_dir_path}/#{dir}")
    end
  end
end