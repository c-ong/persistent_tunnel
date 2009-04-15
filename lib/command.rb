module PersistentTunnel
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

  # TODO:
  #class CreateConnectionCommand < Command
  #  attrs :connection_id => :long,
  #        :address => :string,
  #        :port, :integer
  #end

  class CreateConnectionCommand < Command
    attr_reader :connection_id

    def initialize(connection_id)
      @connection_id = connection_id
    end

    def to_s
      super + [@connection_id].pack('L')
    end

    def self.parse(s)
      connection_id, rest = s.unpack('La*')
      return nil  if ! connection_id

      s.replace(rest)
      CreateConnectionCommand.new(connection_id)
    end
  end

  class CloseConnectionCommand < Command
    attr_reader :connection_id
    def initialize(connection_id)
      @connection_id = connection_id
    end

    def to_s
      super + [@connection_id].pack('L')
    end

    def self.parse(s)
      connection_id, rest = s.unpack('La*')
      return nil  if ! connection_id

      s.replace(rest)
      CloseConnectionCommand.new(connection_id)
    end
  end

  class SendDataCommand < Command
    attr_reader :connection_id, :seq, :data
    def initialize(connection_id, seq, data)
      @connection_id, @seq, @data = connection_id.to_i, seq.to_i, data
    end

    def to_s
      super + [@connection_id, @seq, @data.size].pack('LLS') + @data
    end

    def self.parse(s)
      connection_id, seq, data_size, rest = s.unpack('LLSa*')
      return nil  if ! connection_id or ! seq or ! data_size or rest.size < data_size

      s.replace(rest[data_size..-1])
      SendDataCommand.new(connection_id, seq, rest[0, data_size])
    end
  end

  class SendDataAckCommand < Command
    attr_reader :connection_id, :seq
    def initialize(connection_id, seq)
      @connection_id, @seq = connection_id, seq
    end

    def to_s
      super + [@connection_id, @seq].pack('LL')
    end

    def self.parse(s)
      connection_id, seq, rest = s.unpack('LLa*')
      return nil  if ! connection_id or ! seq

      s.replace(rest)
      SendDataAckCommand.new(connection_id, seq)
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
end
