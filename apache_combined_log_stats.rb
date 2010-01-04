require 'time'
require 'pp'

require 'rubygems'
require 'active_support'

class ApacheCombinedLogEntry
  attr_accessor :ip, :ident, :user, :time, :request, :status_code, :size, :referrer, :user_agent

  def initialize(attrs={})
    attrs.each { |k,v| send "#{k}=", v }
  end

  def hour
    time.hour
  end

  def http_method
    request.split[0]
  end

  def http_version
    request.split[2]
  end

  def request_uri
    request.split[1]
  end
end

module LineParser
  def self.parse(text)
    requests = []
    text.each_line do |l|
      next if l.blank?
      requests << parse_line(l)
    end
    ApacheCombinedLog.new requests
  end

  def self.parse_line(line)
    parts = line.split
    ApacheCombinedLogEntry.new(
      :ip          => parts[0],
      :ident       => parts[1],
      :user        => parts[2],
      :time        => _parse_time([parts[3,2]].join(" ")),
      :request     => _remove_quotations(parts[5,3].join(" ")),
      :status_code => parts[8],
      :size        => parts[9],
      :referrer    => _remove_quotations(parts[10].gsub('"', "")),
      :user_agent  => _remove_quotations(parts[11,(parts.size-11)].join(" "))
    )
  end

  def self._parse_time(raw_time_string)
    formatted_time_string = _remove_brackets(raw_time_string).sub(":", " ")
    Time.parse(formatted_time_string).utc
  end

  def self._remove_brackets(string)
    string.gsub("[", "").gsub("]", "")
  end

  def self._remove_quotations(string)
    string.gsub('"', "")
  end
end

class ApacheCombinedLog
  def initialize(requests)
    @requests = requests
  end

  def hour_histogram
    hours = _setup_histogram_values(:hour)
    (0..23).inject([]) do |array, hour|
      array << [hour, hours[hour]]
    end
  end

  %w( http_method http_version ident ip referrer request request_uri size 
        status_code user user_agent ).each do |method|
    define_method("#{method}_histogram") do 
      _calculate_histogram(method.intern)
    end
  end

  def _calculate_histogram(attribute)
    stats = _setup_histogram_values(attribute)
    stats.keys.sort_by { |key| -stats[key] }.inject([]) do |array, rec|
      array << [rec, stats[rec]]
    end
  end

  def _setup_histogram_values(attribute)
    stats = {}
    @requests.each do |request|
      stats[request.send attribute] ||= 0
      stats[request.send attribute] += 1
    end
    return stats
  end
end

module ApacheCombinedLogStats
  def self.run(file)
    File.open(file, 'r') do |log_file|
      log = LineParser.parse(log_file)
      %w( http_method http_version ip ident referrer request request_uri 
          size status_code user user_agent ).each do |attribute|
        _puts_heading(attribute)
        pp log.send("#{attribute}_histogram")
      end
    end
  end

  def self._puts_heading(text)
    puts "*************************"
    puts "** #{text} histogram"
    puts "*************************"
  end
end
