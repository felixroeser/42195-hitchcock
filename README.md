## 42915-hitchcock

Will at some point provide the director for [42195](https://github.com/felixroeser/42195)

### Getting started

````
export ZOOKEEPERS=10.1.1.10
export ENV=dev
export CLUSTER=cluster1
bundle install --deployment
bundle exec ./bin/hitchcock haproxy_config > /tmp/haproxy.cfg
sudo haproxy -f /tmp/haproxy.cfg -d
````