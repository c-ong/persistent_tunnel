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

      def attrs(*attrs)
        @attrs ||= begin
          attrs = [*attrs].flatten.map {|p| p.to_a.flatten }  # convert hashes to arrays
          define_methods(attrs)

          attrs
        end
      end

      def define_methods(attrs)
        names = attrs.map {|k,v| k }
        class_eval %{
          attr_reader :#{names * ", :"}

          def initialize(#{names * ","})
            @#{names * ", @"} = #{names * ","}
          end
        }
      end

      def parse(s)
        code, rest = s.unpack('Ca*')

        klass = COMMAND_CODES[code]
        raise "Unknown command code: #{code}"  if ! klass

        vals = []
        klass.attrs.each do |_, type|
          case type
          when :long
            val, rest = rest.unpack('La*')
          when :short
            val, rest = rest.unpack('Sa*')
          when :string
            size, rest = rest.unpack('Sa*')
            val = rest.slice!(0, size)  if size and rest.size >= size
          end

          return nil  if ! val

          vals << val
        end
        s.replace(rest)

        klass.new(*vals)
      end
    end

    def to_s
      data = [self.class.code].pack('C')

      self.class.attrs.each do |name, type|
        val = instance_variable_get("@#{name}")
        case type
        when :long
          data << [val].pack('L')
        when :short
          data << [val].pack('S')
        when :string
          data << [val.size].pack('S') << val
        end
      end

      data
    end

    class CreateConnection < Command
      attrs :connection_id => :long
    end
    
    class CloseConnection < Command
      attrs :connection_id => :long
    end
    
    class SendData < Command
      attrs [:connection_id => :long],
            [:seq => :long],
            [:data => :string]
    end

    class SendDataAck < Command
      attrs [:connection_id => :long],
            [:seq => :long]
    end

    class RegisterControlConnection < Command
      attrs :control_connection_id => :short
    end
  end
end
