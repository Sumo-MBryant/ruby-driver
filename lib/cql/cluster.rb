# encoding: utf-8

module Cql
  class Cluster
    State = Struct.new(:hosts)
    Host  = Struct.new(:ip, :rack, :datacenter, :release_version)

    def initialize(control_connection, cluster_state, client_options, settings)
      @control_connection = control_connection
      @state              = cluster_state
      @options            = client_options
      @settings           = settings
      @sessions           = ThreadSafe.new(::Set.new)
    end

    def hosts
      @state.hosts.map {|_, h| Cql::Host.new(h.ip, h.rack, h.datacenter, h.release_version)}
    end

    def connect_async(keyspace = nil)
      options = @options.merge({
        :compressor           => @settings.compressor,
        :logger               => @settings.logger,
        :protocol_version     => @settings.protocol_version,
        :hosts                => @state.hosts.values.map {|host| host.ip},
        :keyspace             => keyspace,
        :connections_per_node => 1,
        :default_consistency  => @settings.default_consistency,
        :port                 => @settings.port,
        :connection_timeout   => @settings.connection_timeout,
        :credentials          => @settings.credentials,
        :auth_provider        => @settings.auth_provider
      })

      client  = Client::AsynchronousClient.new(options)
      session = Session.new(@sessions, client)

      client.connect.map { @sessions << session; session }
    end

    def connect(keyspace = nil)
      connect_async(keyspace).get
    end

    def close_async
      f = Future.all(*(@sessions.map {|s| s.close_async}))
      f = f.flat_map { @control_connection.close_async }
      f.map(self)
    end

    def close
      close_async.get
    end
  end
end

require 'cql/cluster/control_connection'
