require 'test/unit'
require File.dirname(__FILE__) + '/../lib/command'

module PersistentTunnel
  class CommandTest < Test::Unit::TestCase
    def test_create_connection_command
      cmd = Command::CreateConnection.new(5)
      cmd = Command.parse(cmd.to_s)
      assert_equal Command::CreateConnection, cmd.class
      assert_equal 5, cmd.connection_id
    end

    def test_close_connection_command
      cmd = Command::CloseConnection.new(99)
      cmd = Command.parse(cmd.to_s)
      assert_equal Command::CloseConnection, cmd.class
      assert_equal 99, cmd.connection_id
    end

    def test_send_data_command
      cmd = Command::SendData.new(42, 18, 'abcdefg')
      cmd = Command.parse(cmd.to_s)
      assert_equal Command::SendData, cmd.class
      assert_equal 42, cmd.connection_id
      assert_equal 18, cmd.seq
      assert_equal 'abcdefg', cmd.data
    end

    def test_send_data_ack_command
      cmd = Command::SendDataAck.new(42, 18)
      cmd = Command.parse(cmd.to_s)
      assert_equal Command::SendDataAck, cmd.class
      assert_equal 42, cmd.connection_id
      assert_equal 18, cmd.seq
    end

    def test_parse_half_command
      cmd1 = Command::SendData.new(1, 1, 'abcdefgh')
      cmd2 = Command::SendData.new(1, 2,  'ijklmnop')
      cmd2_s_1 = cmd2.to_s[0..6]
      cmd2_s_2 = cmd2.to_s[7..-1]
      
      data = cmd1.to_s + cmd2_s_1

      cmd = Command.parse(data)
      assert_equal Command::SendData, cmd.class
      assert_equal 1, cmd.connection_id
      assert_equal 1, cmd.seq
      assert_equal 'abcdefgh', cmd.data

      assert_equal 7, data.size
      assert_nil Command.parse(data)
      data << cmd2_s_2

      cmd = Command.parse(data)
      assert_equal Command::SendData, cmd.class
      assert_equal 1, cmd.connection_id
      assert_equal 2, cmd.seq
      assert_equal 'ijklmnop', cmd.data
    end

    def test_parse_partial_commands
      cmds = [
        Command::SendData.new(1, 2, 'abcdefghijklmnop'),
        Command::RegisterControlConnection.new(699124),
        Command::CreateConnection.new(11111),
        Command::CloseConnection.new(11111),
        Command::SendDataAck.new(1, 2)
      ]
      buffer = cmds.map {|c| c.to_s }*''
      buf = ''
      parsed_cmds = []
      buffer.each_byte do |b|
        buf << b
        if cmd = Command.parse(buf)
          parsed_cmds << cmd
        end
      end

      expected_classes = [Command::SendData, Command::RegisterControlConnection, Command::CreateConnection, Command::CloseConnection, Command::SendDataAck]
      assert_equal expected_classes, parsed_cmds.map{|c|c.class}
      assert buf.empty?
    end

    def test_register_control_connection_command
      cmd = Command::RegisterControlConnection.new(12345)
      cmd = Command.parse(cmd.to_s)
      assert_equal Command::RegisterControlConnection, cmd.class
      assert_equal 12345, cmd.control_connection_id
    end
  end
end
