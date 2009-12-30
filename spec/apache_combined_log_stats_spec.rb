require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def new_combined_log_entry(attrs={})
  text = { 
    :ip          => '127.0.0.1',
    :ident       => '-',
    :user        => 'frank',
    :time        => '[10/Oct/2000:13:55:36 -0700]',
    :request     => '"GET /apache_pb.gif HTTP/1.0"',
    :status_code => '200',
    :size        => '2326',
    :referrer    => '"http://www.example.com/start.html"',
    :user_agent  => '"Mozilla/4.08 [en] (Win98; I ;Nav)"'
  }.merge(attrs)

  [ text[:ip], text[:ident], text[:user], text[:time], text[:request], text[:status_code], 
    text[:size], text[:referrer], text[:user_agent] ].join(" ")
end

describe ApacheCombinedLogEntry do 
  it "sets attributes correctly on initialization" do 
    @valid_attrs = { :ip => "127.0.0.1", :ident => "-", :user => "frank"}
    entry = ApacheCombinedLogEntry.new(@valid_attrs)
    @valid_attrs.keys.each do |key|
      entry.send(key).should == @valid_attrs[key]
    end
  end

  it "sets the hour method using the time attribute" do 
    entry = ApacheCombinedLogEntry.new(:time => Time.parse("10/Oct/2000 13:55:36 -0700").utc)
    entry.hour.should == 20

  end

  it "sets the HTTP method using the request attribute" do 
    entry = ApacheCombinedLogEntry.new(:request => "GET /apache_pb.gif HTTP/1.0")
    entry.http_method.should == "GET"
  end

  it "sets the request_uri using the request attribute" do 
    entry = ApacheCombinedLogEntry.new(:request => "GET /apache_pb.gif HTTP/1.0")
    entry.request_uri.should == "/apache_pb.gif"
  end

  it "sets the http_version using the request attribute" do 
    entry = ApacheCombinedLogEntry.new(:request => "GET /apache_pb.gif HTTP/1.0")
    entry.http_version.should == "HTTP/1.0"
  end
end

describe LineParser do 
  before(:all) do 
    @line = new_combined_log_entry
  end

  describe "#parse_line" do 
    before do 
      @entry = LineParser.parse_line(@line)
    end

    it "returns an ApacheCombinedLogEntry" do 
      LineParser.parse_line(@line).should be_kind_of(ApacheCombinedLogEntry)
    end

    it "sets the correct ip attribute on the ApacheCombinedLogEntry" do 
      @entry.ip.should == "127.0.0.1"
    end

    it "sets the correct ident attribute on the ApacheCombinedLogEntry" do 
      @entry.ident.should == "-"
    end

    it "sets the correct user attribute on the ApacheCombinedLogEntry" do 
      @entry.user.should == "frank"
    end

    it "sets the correct time attribute on the ApacheCombinedLogEntry" do 
      @entry.time.should be_kind_of(Time)
    end

    it "sets the correct request attribute on the ApacheCombinedLogEntry" do 
      @entry.request.should == "GET /apache_pb.gif HTTP/1.0"
    end

    it "sets the correct status_code attribute on the ApacheCombinedLogEntry" do 
      @entry.status_code.should == "200"
    end

    it "sets the correct size attribute on the ApacheCombinedLogEntry" do 
      @entry.size.should == "2326"
    end

    it "sets the correct referrer attribute on the ApacheCombinedLogEntry" do 
      @entry.referrer.should == "http://www.example.com/start.html"
    end

    it "sets the correct user_agent attribute on the ApacheCombinedLogEntry" do 
      @entry.user_agent.should == "Mozilla/4.08 [en] (Win98; I ;Nav)"
    end
  end

  describe "#_parse_time" do 
    it "returns a Time object if :time != nil" do 
      time = "[10/Oct/2000:13:55:36 -0700]"
      LineParser._parse_time(time).should == Time.parse("10/Oct/2000 13:55:36 -0700").utc
    end
  end

  describe "#_remove_brackets" do 
    it "removes left and right brackets from the string" do 
      string = "[this string should not have brackets]"
      LineParser._remove_brackets(string).should == string.gsub("[","").gsub("]","")
    end
  end

  describe "#_remove_quotations" do 
    it "removes quotation marks around a string" do 
      string = '"this string should not have quotations"'
      LineParser._remove_quotations(string).should == string.gsub('"', "")
    end
  end

  describe "#parse" do 
    it "returns an ApacheCombinedLog object" do 
      LineParser.parse("").should be_kind_of(ApacheCombinedLog)
    end
  end
end

describe ApacheCombinedLog do 
  before(:each) do 
    @requests = []
    15.times { @requests << LineParser.parse_line(new_combined_log_entry) }
  end

  describe "#hour_histogram" do 
    # #hour_histogram is a special case of histogram
    it "returns an array of arrays that contain the hour and # of requests" do 
      10.times do 
        @requests << LineParser.parse_line(
          new_combined_log_entry(:time => '[10/Oct/2000:6:55:36 -0700]' )
        )
      end

      log = ApacheCombinedLog.new @requests
      log.hour_histogram[20].should == [20,15]
      log.hour_histogram[13].should == [13,10]
    end
  end

  describe "#_calculate_histogram" do 
    it "returns an array of arrays that contain the uri and # of requests" do 
      log = ApacheCombinedLog.new @requests

      %w( http_method http_version ip ident referrer request request_uri 
          size status_code user user_agent ).each do |attribute|
        log.send("#{attribute}_histogram")[0][1].should == 15
      end
    end
  end
end
