require 'rubygems'
require 'ruby-debug'

raise 'bad args -- want glob, sess' unless ARGV.length == 2
session = ARGV[1]

a = /^(Processing[^\n]* at ([^\)]*)[^\n]*\n  Session ID: #{session}.*?\})\n/m


settings = []
for filename in Dir.glob(ARGV[0]) do
 all = File.read(filename);
 print "read #{filename}--scanning\n"
 all.scan(a) do |setting| # could do--replace default named ones with their line number :)
    settings << [setting[1], setting[0]]
 end
 print "done with file\n"
end 

for date, setting in settings.sort
 print setting, "\n\n"
end
