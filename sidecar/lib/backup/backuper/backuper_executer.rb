require 'logger'
require 'fileutils'
require_relative 'backuper'
require_relative 'precondition_exception'

class BackuperExecuter

  @logger
  @backup_dir

  def initialize(backup_dir)
    @logger = Logger.new(STDOUT)
    @logger.progname = self.class.name
    @backup_dir = backup_dir
  end

  def executeBackuper(backuper)
    unless backuper.kind_of? Backuper
      raise "#{backuper.class.name} is not an instance of #{Backuper.class.name}"
    end

    begin
      @logger.debug "Calling #{backuper.class.name}"
      backuper.checkPrecondition
      backuper.preBackup
      backuper.backup!(@backup_dir)
      @logger.debug "Finished #{backuper.class.name}"
    rescue PreconditionException => e
      @logger.error("Precondition for #{backuper.class.name} not fulfilled: #{e.message}")
      raise e
    ensure
      backuper.postBackup
    end

  end

end