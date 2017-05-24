# fluent-plugin-festival
Fluentd Input Plugin for FESTIVAL platform

## What is FESTIVAL?

The development of the Internet of Things is set to have a strong impact on many aspects of society. Test-beds and experimental facilities, both of small scale and up to city scale, will be an essential enabler to facilitate the development of this vision. Facilitating the access to these test-beds to a large community of experimenters approach is a key asset to the development of a large and active community of application developers, necessary to address the many challenges faced by European and Japanese societies.

[FESTIVAL project](http://www.festival-project.eu/)’s vision is to provide IoT experimentation platforms providing interaction facility with physical environments and end-users, where experimenters can validate their Smart ICT service developments in various domains such as smart city, smart building, smart public services, smart shopping, participatory sensing, etc. FESTIVAL testbeds will connect cyber world to the physical world, from large scale deployments at a city scale, to small platforms in lab environments and dedicated physical spaces simulating real-life settings. Those platforms will be connected and federated via homogeneous access APIs with an “Experimentation as a Service” (EaaS) model for experimenters to test their added value services.

fluent-plugin-festival provides input plugin for FESTIVAL platform.


## Installation

```
gem install fluent-plugin-festival
```

fluent-plugin-festival requires Ruby version >= 2.1.0.

## Usage

fluent-plugin-festival has Input Plugins for FESTIVAL platform.


### Input Plugin (Fluent::FestivalInput)

Input Plugin can receive events from FESTIVAL EaaS API Server. It can be used via source directive in the configuration. Since FESTIVAL platform requires an authentication, before subscribing resource information, the user needs to create own FESTIVAL platform account via [FESTIVAL portal](https://experiments.festival-project.eu/). After creating an account, please make a configuration file with source directive. detail options of source directive is as follows.

```
<source>
  @type festival
  tag tag_name
  email festival_portal_login_name
  password festival_portal_password
  polling_interval 30
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/train_station_kyoto001_humidity-info-value/current_data
    fixed_location [135.0, 35.0]
  </resource>
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/train_station_kyoto001_barometer-info-value/current_data
    require_location
  </resource>
</source>

<source>
  @type festival
  tag tag_name
  email festival_portal_login_name
  password festival_portal_password
  polling_interval 180
  <resource>
    path /aggregators/IOT-0/testbeds/smartsantander/resources/smartsantander_u7jcfa_f3176-chemicalAgentAtmosphericConcentration:airParticles-sensor/current_data
  </resource>
</source>
```

- **tag** (required): Tag name appended to the input data inside fluentd network
- **email** (required): email address (login name) to login https://experiments.festival-project.eu/
- **password** (required): password for the login_name
- **polling_interval** (optional): Polling interval (seconds) for accessing EaaS API (default: 60 seconds)
- **resource** (at least one entry is required): The target resources to obtain sensor data. multiple resources can be specified by multiple <resource> tags. If a user wants to specify different polling interval for each resource, it must be specified different <source> tags.
  - **path** (at least one entry is required): The target resource path name should be specified. The pathname should specify only under aggregator part and target data type. Currently, only "current_data" type is supported.
 (e.g. /aggregators/IOT-0/testbeds/jose/resources/train_station_hyogo001_barometer-info-value/current_data).
  - **fixed_location**: The target resource location can be specified by longitude and latitude values as an array, e.g. [135.0, 35.0]. The specified location is added to each sensor data.
  - **require_location**: If the target resource is moving object, its dynamic location must be obtained from FESTIVAL platform. When this option is specified, the resource location is retrieved via REST API.

If the time field is empty, this plugin automatically set the finished time of data downloading. If multiple sensor data specified simultaneously, the time difference may become larger than single datum case. A sample data format is shown below.

```
{
  "resourceName": "/aggregators/IOT-0/testbeds/jose/resources/hyogo001_barometer-info-value/current_data",
  "location":{"lon":135.0,"lat":35.0},
  "dataValue": "1001.16"
}
```

## Contributing

1. Fork it ( http://github.com/toyokazu/fluent-plugin-festival/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [Apache License Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
