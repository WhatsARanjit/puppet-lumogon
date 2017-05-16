require 'puppet'
require 'puppet/face'
require 'puppet/util/puppetdb'
require 'puppet/util/puppetlumogon'
require 'json'

Puppet::Face.define(:lumogon, '0.1.0') do
  summary 'Post puppet report data to Lumogon'
  copyright 'WhatsARanjit', 2017
  license 'Apache-2.0'

  lumogon         = Puppet::Util::Puppetlumogon.new
  puppetdb_config = lumogon.puppetdb_config
  output          = []

  action :reports do
    summary 'Upload a node\'s latest report to Lumogon'
    arguments '[node_name]'

    option '--puppetdb PDBSERVER' do
      summary 'Provide PuppetDB server'
      default_to { false }
    end

    option '--puppetdb_port PDBPORT' do
      summary 'Provide PuppetDB port'
      default_to { false }
    end

    when_invoked do |nodename, options|
      puppetdb_server   = options[:puppetdb]      || puppetdb_config['server']
      puppetdb_port     = options[:puppetdb_port] || puppetdb_config['port']
      puppetdb_endpoint = puppetdb_config['endpoint']
      query             = [ 'and', [ '=', 'latest_report?', true ], [ '=', 'certname', nodename ]]
      json_query        = URI.escape(query.to_json)

      node_report = lumogon.do_https(
        "https://#{puppetdb_server}:#{puppetdb_port}/#{puppetdb_endpoint}/reports?query=#{json_query}",
        'GET',
        )
      lumogon.process_report(node_report.body)
    end

    when_rendering :console do |output|
      output
    end
  end

  action :facts do
    summary 'Upload a node\'s facts to Lumogon'
    arguments '[node_name]'

    option '--puppetdb PDBSERVER' do
      summary 'Provide PuppetDB server'
      default_to { false }
    end

    option '--puppetdb_port PDBPORT' do
      summary 'Provide PuppetDB port'
      default_to { false }
    end

    when_invoked do |nodename, options|
      puppetdb_server   = options[:puppetdb]      || puppetdb_config['server']
      puppetdb_port     = options[:puppetdb_port] || puppetdb_config['port']
      puppetdb_endpoint = puppetdb_config['endpoint']
      query             = [ '=', 'certname', nodename ]
      json_query        = URI.escape(query.to_json)

      node_report = lumogon.do_https(
        "https://#{puppetdb_server}:#{puppetdb_port}/#{puppetdb_endpoint}/facts?query=#{json_query}",
        'GET',
        )
      lumogon.process_facts(node_report.body)
    end

    when_rendering :console do |output|
      output
    end
  end

  action :fact do
    summary 'Upload a fact from all nodes to Lumogon'
    arguments '[fact_name],[fact_name]'

    option '--puppetdb PDBSERVER' do
      summary 'Provide PuppetDB server'
      default_to { false }
    end

    option '--puppetdb_port PDBPORT' do
      summary 'Provide PuppetDB port'
      default_to { false }
    end

    when_invoked do |factname, options|
      puppetdb_server   = options[:puppetdb]      || puppetdb_config['server']
      puppetdb_port     = options[:puppetdb_port] || puppetdb_config['port']
      puppetdb_endpoint = puppetdb_config['endpoint']

      node_report = []
      factname.split(',').each do |f|
        data = lumogon.do_https(
          "https://#{puppetdb_server}:#{puppetdb_port}/#{puppetdb_endpoint}/facts/#{f}",
          'GET',
          ).body
        node_report << JSON.parse(data)
      end
      lumogon.process_fact(node_report.flatten)
    end

    when_rendering :console do |output|
      output
    end
  end
end
