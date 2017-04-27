require_relative '../helper'
require 'fluent/test/driver/input'
require 'fluent/plugin/in_festival'

class FestivalInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end


  CONFIG = %[
  ]

  def create_driver(conf = CONFIG, opts = {}) 
    Fluent::Test::Driver::Input.new(Fluent::Plugin::FestivalInput, opts: opts).configure(conf)
  end

  sub_test_case "configure" do
    test "tag email password aggregator_id testbed_id resource_id polling_interval" do
      d = create_driver %[
          tag test
          email hoge@foobar.com
          password login_password
          polling_interval 30
          <resource>
            path /aggregators/IOT-0/testbeds/jose/resources/hyogo001_barometer-info-value/current_data
          </resource>
          <resource>
            path /aggregators/IOT-0/testbeds/jose/resources/kyoto001_barometer-info-value/current_data
          </resource>
      ]
      assert_equal 'test', d.instance.tag
      assert_equal 'login_password', d.instance.password
      assert_equal 30, d.instance.polling_interval
      assert_equal '/aggregators/IOT-0/testbeds/jose/resources/hyogo001_barometer-info-value/current_data', d.instance.resources[0].path
      assert_equal '/aggregators/IOT-0/testbeds/jose/resources/kyoto001_barometer-info-value/current_data', d.instance.resources[1].path
    end
  end
end
