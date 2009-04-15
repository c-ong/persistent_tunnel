require 'test/unit'
require File.dirname(__FILE__) + '/../lib/command'

module PersistentTunnel
  class CommandTest < Test::Unit::TestCase
    def test_create_connection_command
      cmd = CreateConnectionCommand.new(5)
      cmd = Command.parse(cmd.to_s)
      assert_equal CreateConnectionCommand, cmd.class
      assert_equal 5, cmd.connection_id
    end

    def test_close_connection_command
      cmd = CloseConnectionCommand.new(99)
      cmd = Command.parse(cmd.to_s)
      assert_equal CloseConnectionCommand, cmd.class
      assert_equal 99, cmd.connection_id
    end

    def test_send_data_command
      cmd = SendDataCommand.new(42, 18, 'abcdefg')
      cmd = Command.parse(cmd.to_s)
      assert_equal SendDataCommand, cmd.class
      assert_equal 42, cmd.connection_id
      assert_equal 18, cmd.seq
      assert_equal 'abcdefg', cmd.data
    end

    def test_send_data_ack_command
      cmd = SendDataAckCommand.new(42, 18)
      cmd = Command.parse(cmd.to_s)
      assert_equal SendDataAckCommand, cmd.class
      assert_equal 42, cmd.connection_id
      assert_equal 18, cmd.seq
    end

    def test_parse_half_command
      cmd1 = SendDataCommand.new(1, 1, 'abcdefgh')
      cmd2 = SendDataCommand.new(1, 2,  'ijklmnop')
      cmd2_s_1 = cmd2.to_s[0..6]
      cmd2_s_2 = cmd2.to_s[7..-1]
      
      data = cmd1.to_s + cmd2_s_1

      cmd = Command.parse(data)
      assert_equal SendDataCommand, cmd.class
      assert_equal 1, cmd.connection_id
      assert_equal 1, cmd.seq
      assert_equal 'abcdefgh', cmd.data

      assert_equal 7, data.size
      assert_nil Command.parse(data)
      data << cmd2_s_2

      cmd = Command.parse(data)
      assert_equal SendDataCommand, cmd.class
      assert_equal 1, cmd.connection_id
      assert_equal 2, cmd.seq
      assert_equal 'ijklmnop', cmd.data
    end

    def test_parse_partial_commands
      cmds = [
        SendDataCommand.new(1, 2, 'abcdefghijklmnop'),
        RegisterControlConnectionCommand.new(699124),
        CreateConnectionCommand.new(11111),
        CloseConnectionCommand.new(11111)
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

      expected_classes = [SendDataCommand, RegisterControlConnectionCommand, CreateConnectionCommand, CloseConnectionCommand]
      assert_equal expected_classes, parsed_cmds.map{|c|c.class}
      assert buf.empty?
    end

    def test_register_control_connection_command
      cmd = RegisterControlConnectionCommand.new(12345)
      cmd = Command.parse(cmd.to_s)
      assert_equal RegisterControlConnectionCommand, cmd.class
      assert_equal 12345, cmd.control_connection_id
    end
  end
end
