
require 'awesome_print'

module Hitchcock

  class Hacky
    include ERB::Util

    def initialize(opts={})
      @env     = opts['env'] || ENV['ENV']
      @cluster = opts['cluster'] || ENV['CLUSTER']
      @zk      = ZK.new(opts['zookeepers'] || ENV['ZOOKEEPERS'].split(',').collect { |z| "#{z}:2181" }.join(','))

      @marathon_instances = [@zk.get('/marathon/leader/member_0000000000').first]
      @mesos_instances    = @zk.children('/mesos').collect { |c| @zk.get("/mesos/#{c}").first.split('@').last }

      @marathon = Marathon::Client.new(
        "http://#{@marathon_instances.first}"
      )

      @haproxy_pid = "/var/run/haproxy.pid"
      @haproxy_cfg = "/tmp/haproxy.cfg"
    end

    def endpoints
      response = @marathon.endpoints

      return @endpoints = {} if response.error || !response.parsed_response

      @endpoints = response.parsed_response.reduce({}) do |h, app|
        id = app['id'].split('-')[0..-2].join('-')
        v  = app['id'].split('-')[-1].gsub('v', '') rescue '0.0.0'

        h[ id ] ||= {}
        h[ id ][v] = {
          'name' => "#{id}-v#{v}",
          'version' => v,
          'ports' => app['ports'], 
          'instances' => app['instances']
        }
        
        h
      end
    end

    def reduced_endpoints
      @reduced_endpoints = endpoints.reduce({}) do |h, (app, versions)|
        h[app] ||= {}

        versions.each do |(version, data)|
          next if data['instances'].size == 0

          major, minor, patch = version.split('.')

          [ [], [major], [major, minor], [major, minor, patch] ].each do |a|
            next if a.size > 1 && a.compact.size != a.size
            h[app][ a ] = data if h[app][ a ].nil? || data['version'] > h[app][ a ]['version']
          end
        end

        h
      end
    end

    def render_haproxy_cfg
      reduced_endpoints if @reduced_endpoints.nil?
      template = File.read( File.expand_path('../../templates/haproxy.cfg.erb', __FILE__) )
      ERB.new(template).result(binding)
    end

    # just the happy path...
    def run
      Hitchcock.logging.debug "called run..."
      reduced_endpoints

      haproxy_start! unless haproxy_running?
      current_reduced_endpoints_hash = @reduced_endpoints.hash

      # before listening to ZK events => do it stupid
      while true do
        sleep 10
        if reduced_endpoints.hash != current_reduced_endpoints_hash
          current_reduced_endpoints_hash = @reduced_endpoints.hash
          haproxy_start!(true)
        end
      end
    end

    def haproxy_running?
      return nil unless pid = File.read( @haproxy_pid ).to_i rescue nil

      Process.getpgid(pid) rescue nil ? pid : nil
    end

    def haproxy_start!(restart=false)
      File.open(@haproxy_cfg, "w+") { |file| file.puts render_haproxy_cfg }
      `haproxy -f #{@haproxy_cfg} -D -p #{@haproxy_pid} #{"-st $(cat #{@haproxy_pid})" if restart}`
      Hitchcock.logging.info "(Re)started haproxy"
      print_config
    end

    def print_config
      @endpoints.each do |app, versions|
        Hitchcock.logging.info [app, versions.keys]
      end
    end

  end

end
