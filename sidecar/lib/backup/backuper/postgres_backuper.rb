require_relative 'backuper'
require_relative 'precondition_exception'
require_relative '../../shell_executor'
require 'pg'
require 'mkmf'

class PostgresBackuper < Backuper
  include ShellExecutor

  def checkPrecondition
    @logger.info('Checking Environment variables')
    variables = %w{POSTGRES_HOST POSTGRES_PASSWORD POSTGRES_DB POSTGRES_USER}
    missing = variables.find_all { |v| ENV[v].nil? }
    unless missing.empty?
      raise PreconditionException, "The following variables are missing but are needed for #{self.class.name}: #{missing.join(', ')}."
    end
    @db_host = ENV['POSTGRES_HOST']
    @db_password = ENV['POSTGRES_PASSWORD']
    @db_name = ENV['POSTGRES_DB']
    @db_user = ENV['POSTGRES_USER']

    @logger.info('Checking if pg_dump can be found in path')
    if (find_executable 'pg_dump').nil?
      raise PreconditionException, "pg_dump is not installed but required for #{self.class.name}! Make sure that pg_dump is in the PATH"
    end

    @logger.info('Check connection to postgres database')
    begin
      con = PG.connect :host => @db_host, :dbname => @db_name, :user => @db_user, :password => @db_password
    rescue  PG::ConnectionBad => e
      @logger.error("Connection to database failed with error #{e.message}")
      raise PreconditionException, "Connection to Postgres failed: #{e.message}"
    end

    true
  end

  def backup!(backup_dir)
    ENV['PGPASSWORD'] = @db_password
    now = Time.now.strftime("%Y-%m-%d_%H-%M")
    target_path = "#{backup_dir}/#{now}_nextcloud-db.sql.gz"
    dump_cmd = "pg_dump --host=#{@db_host} --username=#{@db_user} #{@db_name}"
    gzip_cmd = "gzip > #{target_path}"
    exec!([dump_cmd, gzip_cmd].join(' | '))
    @logger.info("DB Dump created: '#{target_path}'")
  end

end