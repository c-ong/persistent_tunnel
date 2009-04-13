require 'test/unit'
require File.dirname(__FILE__) + '/../lib/command'

class CommandTest < Test::Unit::TestCase
  def test_create_connection_command
    cmd = CreateConnectionCommand.new('google.com', 80)
    cmd = Command.parse(cmd.to_s)
    assert_equal CreateConnectionCommand, cmd.class
    assert_equal 'google.com', cmd.address
    assert_equal 80, cmd.port
  end

  def test_send_data_command
    cmd = SendDataCommand.new(42, 18, 'abcdefg')
    cmd = Command.parse(cmd.to_s)
    assert_equal SendDataCommand, cmd.class
    assert_equal 42, cmd.connection_id
    assert_equal 18, cmd.seq
    assert_equal 'abcdefg', cmd.data
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

  def test_register_control_connection_command
    cmd = RegisterControlConnectionCommand.new(12345)
    cmd = Command.parse(cmd.to_s)
    assert_equal RegisterControlConnectionCommand, cmd.class
    assert_equal 12345, cmd.control_connection_id
  end
end
