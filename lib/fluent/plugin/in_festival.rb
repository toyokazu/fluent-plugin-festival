require 'fluent/plugin/input'
require 'fluent/event'
require 'fluent/time'
require 'fluent/plugin/festival_proxy'

module Fluent::Plugin
  class FestivalInput < Input
    include FestivalProxy

    Fluent::Plugin.register_input('festival', self)

    helpers :timer

    desc 'FESTIVAL EaaS API URI'
    config_param :api_uri, :string, default: 'https://api.festival-project.eu'
    desc 'email (login_name) for FESTIVAL EaaS API'
    config_param :email, :string
    desc 'password for FESTIVAL EaaS API'
    config_param :password, :string, secret: true
    #base.config_param :keep_alive, :integer, :default => 2
    #base.desc 'Start date of historical data'
    #base.config_param :start_date, :string, :default => Time.now.iso8601
    #base.desc 'End date of historical data'
    #base.config_param :end_date, :string, :default => Time.now.iso8601
    desc 'The tag of the event.'
    config_param :tag, :string
    desc 'Polling interval to get message from FESTIVAL EaaS API'
    config_param :polling_interval, :integer, default: 60

    # <resoruce> tag can be used for specifying multiple resources in a <source> tag
    # If the user wants to specify different format or polling interval for each resource,
    # it should be specified in separated <source> tags.
    # The resources can be specified two types of form URI and id list.
    # Currently, only IOT Gateway aggregator with current_data type is supported.
    # URI case:
    # A resource URI example
    # https://api.festival-project.eu/festival/eaas/experimentation/aggregators/IOT-0/testbeds/jose/resources/hyogo001_barometer-info-value/current_data
    # <resource>
    #   path /aggregators/IOT-0/testbeds/jose/resources/hyogo001_barometer-info-value/current_data
    # </resource>
    #
    # Resource ID case (not supported now):
    # <resource>
    #   aggregator_id IOT-0
    #   testbed_id jose
    #   resource_id hyogo001_barometer-info-value
    # </resource>
    #
    # If you want to specify historical data
    config_section :resource, param_name: :resources, required: true, multi: true do
      desc 'Resource path'
      # e.g. /aggregators/IOT-0/testbeds/jose/resources/hyogo001_barometer-info-value/current_data
      config_param :path, :string
      # e.g. IT-0, OD-0, IOT-0, LL-0
      #base.config_param :aggregator_id, :string, :default => nil
      # e.g. sensinact, jose
      #base.config_param :testbed_id, :string, :default => nil
      # e.g. airsensors_firenze-airsensors-location, hyogo001_barometer-info-valuesfloat
      #base.config_param :resource_id, :string, :default => nil
    end

    def configure(conf)
      super
    end

    def start
      #raise StandardError.new if @tag.nil?
      super
      start_proxy
      timer_execute(:in_festival, @polling_interval) do
        begin
          data = get_data
          emit(data) if !(data.nil? || data.empty?)
        rescue Exception => e
          log.error error: e.to_s
          log.debug(e.backtrace.join("\n"))
          log.trace_backtrace(e.backtrace)
        end
      end
    end

    # Sample data from FESTIVAL IoT Gateway (sensinact)
    # time_key must be set to "date"
    # {"dataValue": "1017.57", "date": "2017-03-29T16:19:15Z"}
    def emit(record)
      begin
        time = Fluent::EventTime.now
        if record.is_a?(Array) # Multiple values case
          mes = Fluent::MultiEventStream.new
          record.each do |single_record|
            # use timestamp of the first sensor (single_record[0])
            mes.add(time, single_record)
          end
          router.emit_stream(@tag, mes)
        else # Single value case
          # use timestamp of the first sensor (single_record[0])
          router.emit(@tag, time, record)
        end
      rescue Exception => e
        log.error error: e.to_s
        log.debug_backtrace(e.backtrace)
      end
    end

    def shutdown
      shutdown_proxy
      super
    end
  end
end
