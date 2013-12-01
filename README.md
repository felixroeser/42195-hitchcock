## 42915-hitchcock

Will at some point provide the director for [42195](https://github.com/felixroeser/42195)

### Getting started

````
export ZOOKEEPERS=10.1.1.10
export ENV=dev
export CLUSTER=cluster1
./bin/hitchcock haproxy_config > /tmp/haproxy.cfg
sudo haproxy -f /tmp/haproxy.cfg -d

# or
./bin/hitchcock start
````

### Build it

````gem build hitchcock.gemspec````

### Create deb package

````
gem build hitchcock.gemspec
mkdir /tmp/gems
gem install --no-ri --no-rdoc --install-dir /tmp/gems hitchcock-0.0.1.gem
cd /tmp/gems
# fpm -d ruby -d rubygems --prefix /var/lib/gems/2.0.0 -s gem -t deb --gem-bin-path /usr/local/bin /tmp/gems/cache/hitchcock-0.0.1.gem
find /tmp/gems/cache -name '*.gem' | xargs -rn1 fpm -d ruby -d rubygems --prefix /var/lib/gems/2.0.0 -s gem -t deb --gem-bin-path /usr/local/bin
````