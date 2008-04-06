# code do:
# the 'inline for rubydoc' option
# useless:
# #doctest_end
# run it from the directory it's in
#
# copy tests out to a file with their name on it, run that :) [so people can debug if wanted?]

require 'rubygems' # for debugger, if they ever want one

@CODE_REGEX = Regexp.new(/(>>|irb.*?>) (.*)/)
RESULT_REGEX = Regexp.new(/=> (.*)/)

def get_ruby_files(dir_name)
ruby_file_names = []

Dir.foreach(dir_name) do |file_name|
unless file_name == '.' || file_name == '..'
full_name = File.join(dir_name, file_name)
if /.*\.rb$/ =~ full_name
ruby_file_names << full_name
elsif File.directory? full_name
sub_files = get_ruby_files(full_name)
ruby_file_names.concat(sub_files) unless sub_files.empty?
end
end
end

ruby_file_names
end

def normalize_result(input)
input.gsub(/:0x([a-f0-9]){8}/, ':0xXXXXXXXX')
end

def failure_report(statement, expected_result, result)
report = "\n FAILED" #add line number logic here
report << " Code: " << statement << "\n"
report << " Expected: " << expected_result << "\n"
report << " But got: " << result
end

def run_doc_tests(doc_test)
execution_context = binding()
statement, report = '', ''
wrong, passed = 0, 0
doc_test.split("\n").each do |line|
case line
when CODE_REGEX
statement << CODE_REGEX.match(line)[2]
when RESULT_REGEX
expected_result = normalize_result(RESULT_REGEX.match(line)[1])
result = normalize_result(eval(statement, execution_context).inspect)
unless result == expected_result
report << failure_report(statement, expected_result, result)
wrong += 1
else
passed += 1
end
statement = ''
end
end
return passed, wrong, report
end

def process_ruby_file(file_name)
tests, succeeded, failed = 0, 0, 0
file_report = ''
code = File.read(file_name)
require 'ruby-debug'

startup_code_for_this_file = code.scan(/begin\s#setup_doctest once_per_file(.*?)=end/m)

if startup_code_for_this_file.length > 0
  raise 'can only do one_time_file_setup declaration once' if startup_code_for_this_file.length > 1 or startup_code_for_this_file[0].length > 1
  startup_code_for_this_file = startup_code_for_this_file[0][0]
  eval startup_code_for_this_file
end

# todo would be nice to have multiple tests in the same comment block
# so a scan + sub scan for doctests
code.scan(/=begin\s#doctest([^\n]*)\n(.*?)=end/m) do |doc_test| # could do--replace default named ones with their line number :)
  require file_name # might as well have its functions available to itself :P
  # todo could tear out anything loaded after each file, I suppose, as active support does
  file_report << "\n Testing '#{doc_test[0]}'..."
  passed, wrong, report = run_doc_tests(doc_test[1])
  file_report += (wrong == 0 ? "OK" : report)
  tests += 1
  succeeded += passed
  failed += wrong
end
file_report = "Processing '#{file_name}'" + file_report unless file_report.empty?
return tests, succeeded, failed, file_report
end

ruby_file_names = get_ruby_files(ARGV[0] || File.dirname(__FILE__))

total_report = "Looking for doctests in #{ruby_file_names.length} files\n"
total_files, total_tests, total_succeeded, total_failed = 0, 0, 0, 0
ruby_file_names.each do |ruby_file_name|
tests, succeeded, failed, report = process_ruby_file(ruby_file_name)
total_files += 1 if tests > 0
total_tests += tests
total_succeeded += succeeded
total_failed += failed
total_report << report << "\n" unless report.empty?
end
total_report << "Total files: #{total_files}, total tests: #{total_tests}, assertions succeeded: #{total_succeeded}, assertions failed: #{total_failed}"
puts total_report
