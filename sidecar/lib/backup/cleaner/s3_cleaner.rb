class S3Cleaner

  def initialize(access_key_id, secret_access_key, host, signature_version = 2)
    @logger = Logger.new(STDOUT)
    @logger.progname = self.class.name
    @connection = Fog::Storage.new(
        provider: 'AWS',
        aws_access_key_id: access_key_id,
        aws_secret_access_key: secret_access_key,
        host: host,
        aws_signature_version: signature_version
    )
  end

  def cleanup(bucket_name, backups_to_keep)
    @logger.info "Cleanup S3: number of backups to keep: #{backups_to_keep}"
    all_files = []
    bucket = @connection.directories.get(bucket_name)
    bucket.files.map do |file|
      all_files.push(file)
    end

    files_sorted = all_files.sort_by {|fog_file| fog_file.last_modified}
    files_to_delete = files_sorted[0, files_sorted.length - backups_to_keep]
    if files_to_delete.to_a.empty?
      @logger.debug "Nothing to clean up"
    else
      files_to_delete.each do |file|
        @logger.info "Deleting file s3://#{bucket_name}/#{file.key} (last_modified: #{file.last_modified})"
        bucket.files.get(file.key).destroy
      end
    end
  end
end
