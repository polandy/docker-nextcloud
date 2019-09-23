require_relative 'backuper'
require_relative '../../shell_executor'
require_relative '../../docker/docker'
require 'fileutils'


class DirectoriesBackuper < Backuper
  include ShellExecutor
  include Docker

  def checkPrecondition
    @logger.info('Checking Environment variables')
    variables = %w{NEXTCLOUD_DIRECTORIES NEXTCLOUD_CONTAINER}
    missing = variables.find_all { |v| ENV[v].nil? }
    unless missing.empty?
      raise PreconditionException, "The following variables are missing but are needed for #{self.class.name}: #{missing.join(', ')}."
    end
    @nextcloud_container_name = ENV['NEXTCLOUD_CONTAINER']

    not_existing_directories = Array.new
    directories_to_backup.each do |directory|
      unless File.exists?(directory)
        not_existing_directories.push(directory)
      end
    end
    @logger.info("Check if directories #{directories_to_backup.join(',')} exist")
    unless not_existing_directories.empty?
      raise PreconditionException, "Not existing directories defined for #{self.class.name} to backup: #{not_existing_directories.join(', ')}"
    end

    true
  end

  def backup!(backup_dir)
    directories_backup_dir="#{backup_dir}/directories/"
    FileUtils.mkdir_p directories_backup_dir
    directories_to_backup.each do |directory|
      target_backup_directory = "#{directories_backup_dir}#{File.basename(directory)}"
      @logger.info("Creating #{target_backup_directory}.tar.gz from #{directory}")
      exec!("tar -zcvf #{target_backup_directory}.tar.gz #{directory}")
    end
  end

  def postBackup
    @logger.debug("called #{__method__.to_s}: Turning off maintenance mode (maintenance mode not needed for next steps)")
    nextcloud_maintenance_off(@nextcloud_container_name)
    @logger.debug("Nextcloud is back in production mode!")
  end

  private

  def directories_to_backup
    directories_to_backup = ENV['NEXTCLOUD_DIRECTORIES'].split(',')
  end

end