require 'json'
require 'net/http'
require 'uri'
require 'openssl'

class Puppet::Util::Puppetlumogon

  def initialize
    @lumogon_hash = Hash.new

    # SSL Options
    @ca_certificate_path = Puppet.settings['localcacert']
    @certificate_path    = Puppet.settings['hostcert']
    @private_key_path    = Puppet.settings['hostprivkey']

  end

  def process_report(report)
    raw_report    = JSON.parse(report)
    raw_report    = raw_report.first if raw_report.is_a?(Array)
    send_report   = lumogonify(raw_report)

    res   = do_https('https://consumer.app.lumogon.com/api/v1', method = 'post', send_report)
    token = JSON.parse(res.body)['Token']
    return "http://reporter.app.lumogon.com/#{token}"
  end

  def do_https(endpoint, method = 'post', data = {}, ssl = true)
    url  = endpoint
    uri  = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)

    if ssl
      http.use_ssl     = true
      http.cert        = OpenSSL::X509::Certificate.new(File.read @certificate_path)
      http.key         = OpenSSL::PKey::RSA.new(File.read @private_key_path)
      http.ca_file     = @ca_certificate_path
      http.verify_mode = OpenSSL::SSL::VERIFY_CLIENT_ONCE
    else
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req              = Object.const_get("Net::HTTP::#{method.capitalize}").new(uri.request_uri)
    req.body         = data.to_json
    req.content_type = 'application/json'

    begin
      res = http.request(req)
    rescue Exception => e
      fail(e.message)
      debug(e.backtrace.inspect)
    else
      res
    end
  end

  private

  def lumogonify(raw)
    @certname = raw['certname']

    @lumogon_hash = {
      '$schema'        => 'http://puppet.com/lumogon/core/draft-01/schema#1',
      'containers'     => {
        @certname => {},
      },
      'client_version' => {
        'BuildSHA'     => raw['hash'],
        'BuildTime'    => raw['end_time'],
        'BuildVersion' => raw['configuration_version'],
      },
    }
    @lumogon_hash['containers'][@certname] = {
      '$schema'             => 'http://puppet.com/lumogon/containerreport/draft-01/schema#1',
      'capabilities'        => {},
      'container_id'        => @certname,
      'container_name'      => @certname,
      'container_report_id' => raw['transaction_uuid'],
      'generated'           => raw['end_time'],
      'noop'                => raw['noop'],
      'noop_pending'        => raw['noop_pending'],
      'producer'            => @certname,
      'producer_timestamp'  => raw['producer_timestamp'],
      'puppet_version'      => raw['puppet_version'],
      'receive_time'        => raw['receive_time'],
      'report_format'       => raw['report_format'],
    }
    @lumogon_hash['containers'][@certname]['capabilities']['host'] = {
      '$schema'   => 'http://puppet.com/lumogon/capability/host/draft-01/schema#1',
      'harvestid' => false,
      'title'     => 'Host Information',
      'type'      => 'attached',
      'payload'   => {
        'certname'              => @certname,
        'cached_catalog_status' => raw['cached_catalog_status'],
        'catalog_uuid'          => raw['catalog_uuid'],
        'code_id'               => raw['code_id'] || 'false',
        'corrective_change'     => raw['corrective_change'] || 'false',
        'end_time'              => raw['end_time'],
        'environment'           => raw['environment'],
        'hash'                  => raw['hash'],
        'start_time'            => raw['start_time'],
        'status'                => raw['status'],
      },
    }
    @lumogon_hash['containers'][@certname]['capabilities']['metrics'] = {
      '$schema'   => 'http://puppet.com/lumogon/capability/host/draft-01/schema#1',
      'harvestid' => false,
      'title'     => 'Metrics',
      'type'      => 'attached',
      'payload'   => write_metrics(raw),
    }
    write_resource_events(raw)
    @lumogon_hash
  end

  def write_resource_events(raw)
    raw['resource_events']['data'].each do |event|
      key = "#{event['resource_type']}[#{event['resource_title']}]"

      @lumogon_hash['containers'][@certname]['capabilities'][key] = {
        '$schema'   => 'http://puppet.com/lumogon/capability/host/draft-01/schema#1',
        'harvestid' => false,
        'title'     => key,
        'type'      => 'attached',
        'payload'   => {
          'containing_class'  => event['containing_class'],
          'containment_path'  => event['containment_path'].join(', '),
          'corrective_change' => event['corrective_change'] || 'false',
          'file'              => event['file'],
          'line'              => event['line'],
          'message'           => event['message'],
          'new_value'         => event['new_value'],
          'old_value'         => event['old_value'],
          'property'          => event['property'],
          'resource_title'    => event['resource_title'],
          'resource_type'     => event['resource_type'],
          'status'            => event['status'],
          'timestamp'         => event['timestamp'],
        },
      }
    end unless ! raw['resource_events']['data']
  end

  def write_metrics(raw)
    data = Hash.new
    raw['metrics']['data'].each do |mhash|
      key   = "#{mhash['category'].capitalize} #{mhash['name']}"
      value = mhash['value'] 
      data[key] = value
    end
    data
  end
end
