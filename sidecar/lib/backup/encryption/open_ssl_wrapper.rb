require 'openssl'
require_relative '../../shell_executor'

class OpenSslWrapper
  include ShellExecutor

  def encrypt(file, key_path)
    @logger = Logger.new(STDOUT)

    encrypted_file_path = "#{file}.aes"
    exec! "openssl aes-256-cbc -salt -pbkdf2 -in #{file} -out #{encrypted_file_path} -pass file:#{key_path}"
    encrypted_file_path
  end

  def decrypt(file, key_path)
    @logger = Logger.new(STDOUT)

    decrypted_file_path = "#{file}.aes"
    exec! "openssl aes-256-cbc -d -salt -pbkdf2 -in #{file} -out #{decrypted_file_path} -pass file:#{key_path}"
  end

end