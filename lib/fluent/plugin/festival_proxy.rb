module Fluent::Plugin
  module FestivalProxy
    require 'uri'
    require 'pathname'
    require 'net/http'
    require 'json'
    require 'time'
    require 'webrick/httputils'

    class FestivalProxyError
    end

    def start_proxy
      log.debug "start festival proxy #{@api_uri}"

      @uri = URI.parse(@api_uri)
      @https = Net::HTTP.new(@uri.host, @uri.port)
      @https.use_ssl = (@uri.scheme == 'https')
      @session = nil
    end

    def shutdown_proxy
      log.debug "shutdown_proxy #{@session.inspect}"
      delete_session
      @https.finish() if @https.active?
    end

    def error_handler(response, message)
      if response.code != "200"
        log.error error: message
        log.debug "code: #{response.code}"
        log.debug "message: #{response.message}"
        log.debug "body: #{response.body}"
        return false
      end
      return true
    end

    def valid_session?
      # TODO validate @session by FESTIVAL EaaS API
      if !@session.nil?
        if Time.now < @session_expires_in
          return true
        end
      end
      return false
    end

    def create_session_request
      session_req = Net::HTTP::Post.new(@uri + '/festival/eaas/security/token')
      session_req.body = {email: @email, password: @password}.to_json
      session_req.content_type = 'application/json'
      session_req
    end

    def create_session
      return @session if valid_session?
      @session_req ||= create_session_request
      session_res = @https.request(@session_req)
      return nil if !error_handler(session_res, 'create_session failed.')
      # access_token is returned as follows
      # {"access_token":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX","expires_in":86400}
      @session = JSON.parse(session_res.body)
      # the expiration time is set to 5 minutes before expiration
      @session_expires_in = Time.now + @session["expires_in"] - 5 * 60
    end

    # TODO: to be implemented
    def delete_session_request
      #Net::HTTP::Delete.new(@uri + "/session/#{@session_key}")
    end

    # TODO: to be implemented
    def delete_session
      #return if !valid_session?
      #del_session_res = @https.request(delete_session_request)
      #error_handler(del_session_res, 'delete_session failed.')
    end

    # type: "current_data", "historical_data"
    #def target_path(type)
    #  if !@aggregator_id.nil? && !@testbed_id.nil? && !@resource_id.nil?
    #    return "/festival/eaas/experimentation/aggregators/#{@aggregator_id}/testbeds/#{@testbed_id}/resources/#{@resource_id}/#{type}"
    #  else
    #    raise Fluent::ConfigError, "aggregator_id, testbed_id and resource_id must be specified."
    #  end
    #end

    def get_data_request(path)
      #get_data_req = @uri + target_path(type)

      get_data_req = @uri +
        case @api_type
        when 'sensinact' 
          Pathname("/sensinact/providers/#{WEBrick::HTTPUtils.escape(path)}").cleanpath.to_s
        else # default (festival)
          Pathname("/festival/eaas/experimentation/#{WEBrick::HTTPUtils.escape(path)}").cleanpath.to_s
        end
      #get_data_req.query = URI.encode_www_form(get_data_params)
      log.debug "#{get_data_req}"
      # currently time window is automatically updated
      #@from = Time.now.iso8601
      get_data_req
    end

    def get_data_header
      header = {
        "Accept": "application/json"
      }
      if @api_type == 'festival'
        return header.merge("X-Auth-Token": @session["access_token"])
      end
      header
    end

    def resource_type(path)
      case @api_type
      when 'sensinact'
        "current_data"
      else
        Pathname(path).basename.to_s
      end
    end

    def resource_path(path)
      case @api_type
      when 'sensinact'
        path
      else
        Pathname(path).dirname.to_s
      end
    end

    def add_location(result, resource)
      if resource.require_location
        log.debug "get_data (location): request #{get_data_request(resource_path(resource.path))}, #{get_data_header.inspect}"
        get_sensor_res = @https.get(get_data_request(resource_path(resource.path)), get_data_header)
        return result if !error_handler(get_sensor_res, "get_data failed.")
        log.debug "get_data: #{get_sensor_res.body}"
        sensor = JSON.parse(get_sensor_res.body)
        # TODO: arbitrary geographicArea type should be supported
        return result.merge({
          "location": {
            "lon": JSON.parse(sensor["location"]["geographicArea"])["coordinates"][0],
            "lat": JSON.parse(sensor["location"]["geographicArea"])["coordinates"][1]
          }
        })
      elsif !resource.fixed_location.nil?
        log.debug "set fixed_location: #{resource.fixed_location.inspect}"
        return result.merge({
          "location": {
            "lon": resource.fixed_location[0].to_f,
            "lat": resource.fixed_location[1].to_f
          }
        })
      end
      return result
    end

    def get_data
      if !valid_session? && @api_type == 'festival'
        return nil if create_session.nil?
        log.debug "session #{@session} created."
      end
      data = []
      #require 'pry-byebug'
      log.debug "@resources: #{@resources.inspect}"
      @resources.each do |resource|
        case resource_type(resource.path)
        when "current_data" then
          log.debug "get_data: request #{get_data_request(resource.path)}, #{get_data_header.inspect}"
          get_data_res = @https.get(get_data_request(resource.path), get_data_header)
          next if !error_handler(get_data_res,"get_data failed.")
          log.debug "get_data: #{get_data_res.body}"
          result = 
            case @api_type
            when 'festival'
              {
                "resourceName": resource.path,
                "dataValue": JSON.parse(get_data_res.body)["dataValue"]
              }
            when 'sensinact'
              {
                "resourceName": resource.path,
                "dataValue": JSON.parse(get_data_res.body)["response"]["value"],
                "timestamp": JSON.parse(get_data_res.body)["response"]["timestamp"]
              }
            else
              return nil
            end
          data << add_location(result, resource)
        when "historical_data" then
          log.error "historical_data is not supported yet"
          next
        else
          log.error "The other resource type is not supported yet"
          log.error "resource_type: #{resource_type(resource.path)}"
          next
        end
      end
      if data.size > 1
        return data
      end
      data[0]
    end

    #  curl --request GET \
    #  --url 'http://sensinact-cea.ddns.net:8099/festival/driver/testbeds/jose/resources/hyogo001_barometer-info-valueasfloat/historical_data?startDate=2017-03-01T00%3A05%3A55Z' \
    #  --header 'cache-control: no-cache' \
    #  --header 'content-type: application/json' \
    #  --header 'postman-token: 6bceac9e-5d14-3c9e-d34c-acbd4922ebfc' \
    #  --header 'userid: me' \
    #  --data '{"options":{"rows":20}}'
    def get_historical_data
      # TODO: to be implemented
    end
  end
end
