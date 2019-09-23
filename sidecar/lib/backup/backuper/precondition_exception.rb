class PreconditionException < StandardError
  def initialize(msg = 'Error in Precondition step')
    super
  end
end