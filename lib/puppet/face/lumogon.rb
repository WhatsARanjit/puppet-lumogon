require 'puppet'
require 'puppet/face'
require 'puppet/util/puppetlumogon'
require 'json'

Puppet::Face.define(:lumogon, '0.1.0') do
  summary 'Post puppet report data to Lumogon'
  copyright 'WhatsARanjit', 2017
  license 'Apache-2.0'

  lumogon = Puppet::Util::Puppetlumogon.new
  output  = []

  action :upload do
    summary 'Upload a node\'s latest report to Lumogon'
    arguments '[node_name]'

    option '--puppetdb PDBSERVER' do
      summary 'Provide PuppetDB server'
      default_to { Puppet.settings['server'] }
    end

    when_invoked do |nodename, options|
      query = [ 'and', [ '=', 'latest_report?', true ], [ '=', 'certname', nodename ]]
      json_query = URI.escape(query.to_json)
      node_report = lumogon.do_https(
        "https://#{options[:puppetdb]}:8081/pdb/query/v4/reports?query=#{json_query}",
        'GET',
        )
      lumogon.process_report(node_report.body)
    end

    when_rendering :console do |output|
      output
    end
  end

end
