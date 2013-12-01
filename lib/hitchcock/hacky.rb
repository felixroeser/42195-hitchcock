
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
        # "http://#{ENV['MARATHON'] || 'marathon.director.cluster1.env'}"
      )
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

    def run
      endpoints
      true
    end

  end

end
