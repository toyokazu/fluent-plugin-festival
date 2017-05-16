# fluent-plugin-festival tutorial

## Install fluentd

```
gem install fluent-plugin-festival
```

fluentd 0.14.x will be installed automatically.


## Create a sample configuration file

Create a sample configuration file as follows. You need to change festival_portal_login_name and festival_portal_password to your account information.

```
% vi fluent.conf
---
<source>
  @type festival
  tag test1
  email festival_portal_registered_email_address
  password festival_portal_password
  polling_interval 30
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/train_station_kyoto001_humidity-info-value/current_data
  </resource>
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/train_station_kyoto001_barometer-info-value/current_data
  </resource>
</source>

<source>
  @type festival
  tag test2
  email festival_portal_registered_email_address
  password festival_portal_password
  polling_interval 180
  <resource>
    path /aggregators/IOT-0/testbeds/smartsantander/resources/smartsantander_u7jcfa_f3176-chemicalAgentAtmosphericConcentration:airParticles-sensor/current_data
  </resource>
</source>

<match *>
  @type stdout
</match>
---
```


## Start fluentd with debug mode

Start fluentd with debug mode as follows.

```
fluentd -c fluent.conf -vvv
```

Then, you can confirm the sensor values are output to your console.

You can try the other resources by browsing resources via FESTIVAL portal and change target resource URI to the ones listed in the resource information.

## Store data into Elasticsearch

About installation, please refer the following page.

https://www.elastic.co/downloads/elasticsearch

In the followings, how to store FESTIVAL platform data into Elasticsearch will be shown.

First of all, you need to create mapping in Elasticsearch. An Elasticsearch server is assumed to run in localhost.

```
vi train_station-mapping.json
---
{
  "train_station": {
    "properties": {
      "timestamp": {
        "type": "date",
        "format": "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
      },
      "resourceName": {
        "type": "keyword"
      },
      "dataValue": {
        "type": "double"
      }
    }
  }
}
---

curl -XPUT 'http://localhost:9200/festival'
curl -XPUT 'http://localhost:9200/festival/train_station/_mapping' -d @train_station-mapping.json
```

```
% vi fluent.conf
---
<source>
  @type festival
  tag test1
  email festival_portal_registered_email_address
  password festival_portal_password
  polling_interval 30
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/train_station_kyoto001_humidity-info-value/current_data
  </resource>
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/train_station_kyoto001_barometer-info-value/current_data
  </resource>
  @label @test0
</source>

<label @test0>
  <filter test*>
    @type record_transformer
    enable_ruby true
    auto_typecast true
    <record>
      timestamp   ${time.strftime("%FT%T.%L%:z")}
    </record>
  </filter>

  # If you want to output the messages not only into Elasticsearch
  # but also into standard output, please enable comment out lines.
  # Configurations for fluent-plugin-elasticsearch must be fluentd
  # 0.12 compatible form because it doesn't support 0.14 yet.
  <match test*>
    @type copy
    <store>
      @type elasticsearch
      host localhost
      port 9200
      index_name festival
      type_name train_station
      logstash_format false
      include_tag_key true
      time_key timestamp
      flush_interval 30s
    </store>
    <store>
      @type stdout
    </store>
  </match>
</label>
```
