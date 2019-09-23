require 'logger'

class Backuper
  @logger

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.progname = self.class.name
  end

  def checkPrecondition
    @logger.info("method #{__method__.to_s} not implemented")
    true
  end

  def preBackup
    @logger.info("method #{__method__.to_s} not implemented")
  end

  def backup!(backup_dir)
    raise "Don't forget do implement the #{__method__.to_s} method!"
  end

  def postBackup
    @logger.info("method #{__method__.to_s} not implemented")
  end

end