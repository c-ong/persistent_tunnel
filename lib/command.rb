class Command
  COMMAND_CODES = {}
  @current_code = 0

  class << self
    attr_accessor :code

    def inherited(subclass)
      code = @current_code += 1
      COMMAND_CODES[code] = subclass
      subclass.code = code
    end

    def parse(s)
      code, rest = s.unpack('Ca*')

      klass = COMMAND_CODES[code]
      raise "Unknown command code: #{code}"  if ! klass

      cmd = klass.parse(rest)
      s.replace(rest)  if cmd
      cmd
    end
  end

  def to_s
    [self.class.code].pack('C')
  end
end

class CreateConnectionCommand < Command
  attr_reader :address, :port

  def initialize(address, port)
    @address, @port = address, port.to_i
  end

  def to_s
    super + [@address, @port].pack("Z*I")
  end

  def self.parse(s)
    address, port, rest = s.unpack("Z*Ia*")
    return nil  if ! address or ! port

    s.replace(rest)
    CreateConnectionCommand.new(address, port)
  end
end

class SendDataCommand < Command
  attr_reader :connection_id, :seq, :data
  def initialize(connection_id, seq, data)
    @connection_id, @seq, @data = connection_id.to_i, seq.to_i, data
  end

  def to_s
    super + [@connection_id, @seq, @data.size].pack('SLS') + @data
  end

  def self.parse(s)
    connection_id, seq, data_size, rest = s.unpack('SLSa*')
    return nil  if ! connection_id or ! seq or ! data_size or rest.size < data_size

    s.replace(rest[data_size..-1])
    SendDataCommand.new(connection_id, seq, rest[0, data_size])
  end
end

class RegisterControlConnectionCommand < Command
  attr_reader :control_connection_id
  def initialize(control_connection_id)
    @control_connection_id = control_connection_id
  end

  def to_s
    super + [@control_connection_id].pack('S')
  end

  def self.parse(s)
    control_connection_id, rest = s.unpack('Sa*')
    return nil  if ! control_connection_id

    s.replace(rest)
    RegisterControlConnectionCommand.new(control_connection_id)
  end
end
