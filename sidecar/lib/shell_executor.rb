module ShellExecutor
  def exec!(cmd)
    @logger.debug("Executing command '#{cmd}'")
    output = %x(#{cmd} 2>&1)
    raise "Error while running command: #{output}" unless $? == 0

    output
  end
end