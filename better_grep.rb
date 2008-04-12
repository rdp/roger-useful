#!/opt/local/bin/ruby
ARGV[0] = ARGV[0].gsub("(", "\\(").gsub(")", "\\)").gsub("\\", "\\\\")

tester = Regexp.new ARGV[0], Regexp::MULTILINE | Regexp::IGNORECASE

for file in Dir.glob ('*') do
  contents = File.read file
  if contents =~ tester
     print "match: #{file}\n"
  end

end
