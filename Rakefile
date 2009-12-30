require 'rake'
require 'apache_combined_log_stats'

require 'pp'

Dir["#{File.expand_path(File.dirname(__FILE__))}/**/tasks/*.rake"].each { |ext| load ext }

task :default => :spec

desc "prints all the histograms available"
task :histograms do 
  file = ENV['FILE'].nil? ? File.expand_path(File.dirname(__FILE__) + "/spec/fixtures/access_log") : ENV['FILE']
  ApacheCombinedLogStats.run(file)
end
