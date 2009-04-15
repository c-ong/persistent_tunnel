module PersistentTunnel
  class Client
    attr_writer :control_connection
    attr_reader :connections

    def initialize(listen_address, control_address)
      parts = listen_address.split(/:/)
      if parts.size == 2
        @listen_host, @listen_port = parts
      else
        @listen_host = '127.0.0.1'
        @listen_port = parts.first
      end
      @control_host, @control_port = control_address.split(/:/)

      @connections = {}
    end

    def start
      EM.connect @control_host, @control_port.to_i, ControlConnection, self
      EM.start_server @listen_host, @listen_port.to_i, LocalConnection, self
    end

    def next_connection_id
      @connection_id ||= 0
      @connection_id += 1
    end

    def send_command(cmd)
      @control_connection.send_data(cmd.to_s)
    end

    class ControlConnection < EventMachine::Connection
      def initialize(client)
        @client = client
        @client.control_connection = self
        @buffer = ''
      end

      def receive_data(data)
        @buffer << data
        while cmd = Command.parse(@buffer)
          case cmd
          when SendDataCommand
            process_send_data(cmd)
          end
        end
      end

      def process_send_data(cmd)
        send_data(SendDataAckCommand.new(cmd.connection_id, cmd.seq))
        local_conn = @client.connections[cmd.connection_id]
        local_conn.send_data(cmd.data)
      end
    end

    class LocalConnection < EventMachine::Connection
      def initialize(client)
        @client = client
        @connection_id = client.next_connection_id
        @client.connection[@connection_id] = self
        @client.send_command(CreateConnectionCommand.new(@connection_id))
      end

      # TODO: add data to buffer, and flush buffer, so when control conn goes down
      # we keep everything in buffer, and flush when it comes up
      def receive_data(data)
        @client.send_command(SendDataCommand.new(@connection_id, data))
      end
    end
  end
end
