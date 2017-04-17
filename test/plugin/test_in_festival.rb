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
          email hoge@foobar.com
          password login_password
          aggregator_id IOT-0
          testbed_id sensinact
          resource_id hyogo001_barometer-info-valuesfloat
          polling_interval 30
          <parse>
            @type json
          </parse>
      ]
      assert_equal 'test', d.instance.tag
      assert_equal 'login_password', d.instance.password
      assert_equal 'IOT-0', d.instance.aggregator_id
      assert_equal 'sensinact', d.instance.testbed_id
      assert_equal 'hyogo001_barometer-info-valuesfloat', d.instance.resource_id
      assert_equal 30, d.instance.polling_interval
    end
  end
end
