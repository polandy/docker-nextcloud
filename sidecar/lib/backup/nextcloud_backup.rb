require 'logger'
require_relative 'backuper/postgres_backuper'
require_relative 'backuper/directories_backuper'
require_relative 'backuper/backuper_executer'
require_relative 'encryption/open_ssl_wrapper'
require_relative 'uploader/s3_uploader'
require_relative 'cleaner/s3_cleaner'
require_relative 'cleaner/local_files_cleaner'
require_relative '../shell_executor'
require_relative '../docker/docker'

class NextcloudBackup
  include ShellExecutor
  include Docker

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.progname = self.class.name
  end

  def run
    begin
      check_required_env_variables
      backup_dir = ENV['BACKUP_DIR']
      nextcloud_container = ENV['NEXTCLOUD_CONTAINER']
      current_backup_dir = create_directory_for_backup(backup_dir)
      @logger.info 'Set nextcloud to maintenance mode'
      nextcloud_maintenance_on(nextcloud_container)

      do_all_backups(current_backup_dir)
      path_to_encrypted_archive = create_archive_and_encrypt_it(current_backup_dir)
      upload_archive_to_s3(path_to_encrypted_archive)
      File.delete(path_to_encrypted_archive) if File.exist?(path_to_encrypted_archive)

      cleanup_old_backups(backup_dir)
      @logger.info 'Nextcloud backup finished!'

    rescue PreconditionException => e
      @logger.error("Error during backup: #{e.message}")
      @logger.error('Abort backup!')
    ensure
      @logger.info 'Set nextcloud back to production mode'
      nextcloud_maintenance_off(nextcloud_container)
    end

  end

  def encrypt_final_archive_if_key_provided(archive_to_encrypt)
    encryption_key_path = ENV['ENCRYPTION_KEY_PATH']
    if !encryption_key_path.nil?
      @logger.info "Going to encrypt #{archive_to_encrypt} with key #{encryption_key_path}"
      encrypted_file_path = OpenSslWrapper.new.encrypt archive_to_encrypt, encryption_key_path
      @logger.info "Encrypted file created: #{encrypted_file_path}"
      encrypted_file_path
    else
      @logger.warn 'Encryption key Environment variable ENCRYPTION_KEY_PATH not set!'
      @logger.warn "#{archive_to_encrypt} won't be encrypted"
    end
  end

  def check_required_env_variables
    variables = %w{BACKUP_DIR NEXTCLOUD_CONTAINER}
    missing = variables.find_all { |v| ENV[v].nil? }
    raise PreconditionException, "The following variables are missing but are needed for #{self.class.name}: #{missing.join(', ')}" unless missing.empty?
  end

  private

  def create_archive_and_encrypt_it(current_backup_dir)
    path_to_archive = create_final_archive_and_delete_backup_directory(current_backup_dir)
    path_to_encrypted_archive = encrypt_final_archive_if_key_provided(path_to_archive)
  end

  def do_all_backups(current_backup_dir)
    backuper_executer = BackuperExecuter.new(current_backup_dir)
    nextcloud_backupers.each do |backuper|
      backuper_executer.executeBackuper(backuper)
    end
  end

  def cleanup_old_backups(backup_dir)
    local_files_cleaner = LocalFilesCleaner.new
    local_files_cleaner.cleanup(number_of_backups_to_keep_local, backup_dir)

    access_key, bucket_name, host, shared_secret = s3_config_values
    s3_cleaner = S3Cleaner.new(access_key, shared_secret, host)
    s3_cleaner.cleanup(bucket_name, number_of_backups_to_keep_s3)
  end

  def number_of_backups_to_keep_s3
    env_variable = 'BACKUPS_TO_KEEP_S3'
    number_of_backups = ENV[env_variable] || 60
    @logger.info "Number of backups to keep on s3 is #{number_of_backups}. To override it set the env variable #{env_variable}"
    number_of_backups
  end

  def number_of_backups_to_keep_local
    env_variable = 'BACKUPS_TO_KEEP_LOCAL'
    number_of_backups = ENV[env_variable] || 14
    @logger.info "Number of backups to keep locally is #{number_of_backups}. To override it set the env variable #{env_variable}"
    number_of_backups
  end

  def upload_archive_to_s3(path_to_encrypted_archive)
    unless path_to_encrypted_archive.to_s.empty?
      @logger.info "Uploading #{path_to_encrypted_archive} to S3"
      access_key, bucket, host, shared_secret = s3_config_values
      s3_uploader = S3Uploader.new(access_key, shared_secret, host)
      s3_uploader.create_bucket bucket
      s3_uploader.upload path_to_encrypted_archive
      @logger.info 'Uploaded successfully'
      path_to_encrypted_archive
    end
  end

  def s3_config_values
    if missing_environment_variables_for_s3.empty?
      access_key = ENV['S3_ACCESS_KEY']
      shared_secret = ENV['S3_SHARED_SECRET']
      host = ENV['S3_HOST']
      bucket = ENV['S3_BUCKET'] || 'nc-backups'
      [access_key, bucket, host, shared_secret]
    end
  end

  def missing_environment_variables_for_s3
    variables = %w{S3_ACCESS_KEY S3_SHARED_SECRET S3_NAMESPACE S3_HOST}
    missing = variables.find_all {|v| ENV[v].nil?}
  end

  def create_final_archive_and_delete_backup_directory(current_backup_dir)
    final_archive_name = "#{current_backup_dir}.tar.gz"
    @logger.info("Creating #{current_backup_dir}.tar.gz from #{current_backup_dir}")
    exec!("tar -cvf #{final_archive_name} #{current_backup_dir}")
    @logger.info("Deleting directory #{current_backup_dir}")
    exec!("rm -r #{current_backup_dir}")
    final_archive_name
  end

  def create_directory_for_backup(backup_dir)
    now = Time.now.strftime('%Y-%m-%d_%H-%M-%s')
    FileUtils.mkdir_p backup_dir
    current_backup_dir = [backup_dir, now + '-nextcloud'].join('/')
    @logger.debug "Creating directory #{current_backup_dir} for backup run!"
    FileUtils.mkdir_p current_backup_dir
    current_backup_dir
  end

  def nextcloud_backupers
    [PostgresBackuper.new,
     DirectoriesBackuper.new]
  end

end