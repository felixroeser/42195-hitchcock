require 'bundler'
Bundler.setup

require 'marathon'
require 'zk'
require 'erb'

module Hitchcock

  class Simple
    include ERB::Util

    def initialize

      @env = ENV['ENV']
      @cluster = ENV['CLUSTER']

      @zk = ZK.new ENV['ZOOKEEPERS'].split(',').collect { |z| "#{z}:2181" }.join(',')

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
          'ports' => app['ports'], 
          'instances' => app['instances']
        }
        
        h
      end
    end

    def render_haproxy_cfg
      template = File.read( File.expand_path('../../templates/haproxy.cfg.erb', __FILE__) )
      out = ERB.new(template).result(binding)
    end

    def info
      puts endpoints.inspect
    end

    def run
      endpoints
      puts render_haproxy_cfg
    end

  end

end
