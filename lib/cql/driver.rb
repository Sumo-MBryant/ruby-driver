# encoding: utf-8

module Cql
  # @private
  class Driver
    def self.let(name, &block)
      define_method(name)        { @instances[name] ||= @defaults.fetch(name) { instance_eval(&block) } }
      define_method(:"#{name}=") { |object| @instances[name] = object }
    end

    let(:request_runner)   { Client::RequestRunner.new }
    let(:io_reactor)       { Reactor.new(Io::IoReactor.new) }
    let(:cluster_registry) { Cluster::Registry.new(logger) }
    let(:cluster_schema)   { Cluster::Schema.new(schema_type_parser) }

    let(:schema_type_parser) { Cluster::Schema::TypeParser.new }

    let(:connector) { Cluster::Connector.new(logger, io_reactor, cluster_registry, connection_options) }

    let(:control_connection) { Cluster::ControlConnection.new(logger, io_reactor, request_runner, cluster_registry, cluster_schema, load_balancing_policy, reconnection_policy, connector, connection_options) }

    let(:cluster) { Cluster.new(logger, io_reactor, control_connection, cluster_registry, cluster_schema, execution_options, connection_options, load_balancing_policy, reconnection_policy, retry_policy, connector) }

    let(:execution_options) do
      Execution::Options.new({
        :consistency => :one,
        :trace       => false,
        :page_size   => 50_000
      })
    end

    let(:connection_options) { Cluster::Options.new(protocol_version, credentials, auth_provider, compressor, port, connection_timeout, connections_per_local_node, connections_per_remote_node) }

    let(:port)                  { 9042 }
    let(:protocol_version)      { 2 }
    let(:connection_timeout)    { 10 }
    let(:logger)                { Client::NullLogger.new  }
    let(:compressor)            { nil }
    let(:credentials)           { nil }
    let(:auth_provider)         { nil }
    let(:load_balancing_policy) { LoadBalancing::Policies::RoundRobin.new  }
    let(:reconnection_policy)   { Reconnection::Policies::Exponential.new(0.5, 30, 2) }
    let(:retry_policy)          { Retry::Policies::Default.new }

    let(:connections_per_local_node)  { 2 }
    let(:connections_per_remote_node) { 1 }

    let(:initial_state_listeners) { [] }

    def initialize(defaults = {})
      @defaults  = defaults
      @instances = {}
    end

    def connect(addresses)
      cluster_registry.add_listener(load_balancing_policy)
      cluster_registry.add_listener(control_connection)
      initial_state_listeners.each do |listener|
        cluster.register(listener)
      end

      addresses.each {|address| cluster_registry.host_found(address)}

      control_connection.connect_async.map(cluster)
    end
  end
end
