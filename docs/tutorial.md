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
  username festival_portal_login_name
  password festival_portal_password
  polling_interval 30
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/hyogo001_barometer-info-value
  </resource>
  <resource>
    path /aggregators/IOT-0/testbeds/jose/resources/kyoto001_barometer-info-value
  </resource>
</source>

<source>
  @type festival
  tag test2
  username festival_portal_login_name
  password festival_portal_password
  polling_interval 180
  <resource>
    path /aggregators/IOT-0/testbeds/smartsantander/resources/smartsantander_u7jcfa_f3176-chemicalAgentAtmosphericConcentration:airParticles-sensor
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
