require 'logger'
require 'fog'
require 'fog-aws'


class S3Uploader

  attr_reader :connection

  def initialize(access_key_id, secret_access_key, host, signature_version = 2)
    @logger = Logger.new(STDOUT)
    @connection = Fog::Storage.new(
      provider: 'AWS',
      aws_access_key_id: access_key_id,
      aws_secret_access_key: secret_access_key,
      host: host,
      aws_signature_version: signature_version
    )
  end

  def create_bucket(bucketname)
    @logger.debug "Creating bucket \"#{bucketname}\""
    @bucket = @connection.directories.create(
      key: bucketname,
      public: true
    )
    @logger.info "Bucket \"#{bucketname}\" on S3 created."
  end

  def upload(file_path)
    @logger.info "Uploading file '#{file_path}'"
    @file = @bucket.files.create(
      key: File.basename(file_path).to_s,
      body: File.open(file_path.to_s),
      public: true
    )
    @logger.info "File '#{File.basename(file_path)}' on S3 created."
  end

end