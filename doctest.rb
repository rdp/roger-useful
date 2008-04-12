# todo:
# the 'inline for rubydoc' option
# low priority:
# make it even more robust to errors--if it errs, look for internal hashes, convert
# Fix so raising errors validates -- currently ignores
# multi line strings
# option to run each in its own directory
# tell them how to change dirs on their own [add an end guy?]
# #doctest_end
# WAY more line logic
# some way of reusing tests, like classes [?] or functions :) -- this doctest gets this replaced with this :P
# normal code inline [maybe that can raise if it errs, maybe more]
# check python's --what they got?
# use rspec, how can it improve?
# todo better params

if ARGV[0] == '--help'
  print "
  use: doctest file_name.rb (or directory_name): default '.'
  -- note it recurses and scans all .rb in that directory and its subdirectories
  ex: doctest .
  doctest file.rb
  doctest dir #also scans its subdirs
"
  exit
end

BINDING = binding()

class DocTest
  CODE_REGEX = Regexp.new(/^(>>|irb.*?>) (.*)/)
  RESULT_REGEX = Regexp.new(/^=> (.*)/)
  EXCEPTION_REGEX = Regexp.new(/^([A-Z][A-Za-z0-9]*):/)

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
=begin
#doctest normalize substring
>> a = DocTest.new
=> #<DocTest:0x37012c>
>> a.normalize_result('0xtion:0x1876bc0 @@p')
=> "0xtion:0xXXXXXXXX @@p"
=end
  def normalize_result(input)
    input.gsub(/:0x([a-f0-9]){5,8}/, ':0xXXXXXXXX')  # makes them all 8 digits long
  end

  def failure_report(statement, expected_result, result)
    report = "\n FAILED" #add line number logic here
    report << " Code: " << statement << "\n"
    report << " Expected: " << expected_result << "\n"
    report << " But got: " << result
  end

=begin
#doctest should match with hashes
>> {1=>1, 2=>2, 3=> 3, 4=>4,5=>5}
=> {5=>5, 1=>1, 2=>2, 3=>3, 4=>4}
now test with different ordered hashes
>> {1=>1, 2=>2, 3=> 3, 4=>4,5=>5}
=> {4=>4, 1=>1, 2=>2, 3=>3, 5=>5}
>> {1=>":0x123456", 2=>2, 3=> 3, 4=>4,5=>5}
=> {4=>4, 1=>":0x123456", 2=>2, 3=>3, 5=>5}
=end
   def dbg
     require 'rubygems'; require 'ruby-debug'; debugger
  end
  def run_doc_tests(doc_test)
    statement, report = '', ''
    wrong, passed = 0, 0
    doc_test.split("\n").each do |line|
      case line
        when CODE_REGEX
          statement << CODE_REGEX.match(line)[2]
        when RESULT_REGEX, EXCEPTION_REGEX
          if line =~ RESULT_REGEX
		expected_result_string = normalize_result(RESULT_REGEX.match(line)[1])
	  else
		raise unless line =~ EXCEPTION_REGEX
		expected_result_string = $1
	  end
	
          begin
		result_we_got = eval(statement, BINDING)
	  rescue Exception => e
		result_we_got = e.class
          end
       
          they_match = false 
          if result_we_got.class.ancestors.include? Hash
            # change them to 'kind of real' hashes, so that we cancompare them and have comparison work--hashes sometimes display in different orders when printed
            expected_result = eval(expected_result_string, BINDING)
	    if eval(normalize_result(result_we_got.inspect), BINDING) == expected_result # todo some tests for this with whack-o stuff thrown in  :)
		# the Hashes matched, string-wise
		they_match = true
	    end
          end

	  they_match = true if expected_result_string =~ /#doctest_fail_ok/
          result_string = normalize_result(result_we_got.inspect)
	  they_match = true if result_string == expected_result_string
          unless they_match
            report << failure_report(statement, expected_result_string, result_string)
            wrong += 1
          else
            passed += 1
          end
          statement = '' # reset it for the next round
      end
    end
    return passed, wrong, report
  end

  def process_ruby_file(file_name)
    tests, succeeded, failed = 0, 0, 0
    file_report = ''
    code = File.read file_name

    startup_code_for_this_file = code.scan(/begin\s#setup_doctest once_per_file(.*?)=end/m)
  
    if startup_code_for_this_file.length > 0
      raise 'can only do one_time_file_setup declaration once' if startup_code_for_this_file.length > 1 or startup_code_for_this_file[0].length > 1
      startup_code_for_this_file = startup_code_for_this_file[0][0]
      begin
      	eval startup_code_for_this_file, BINDING
      rescue Exception => e
	print "Uh oh unable to execute startup code for #{file_name}...continuing #{e}\n"
      end
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
    file_report = "Processing '#{file_name}' from current directory " + file_report unless file_report.empty?
    return tests, succeeded, failed, file_report
  end


end

if $0 == __FILE__
 # parse command line--currently just 'filename' or 'directory name'
 runner = DocTest.new
 if File.directory? ARGV[0] || ''
   ruby_file_names = runner.get_ruby_files(ARGV[0])
 elsif File.exist? ARGV[0] || ''
   ruby_file_names = [ARGV[0]]
 else
   ruby_file_names = runner.get_ruby_files('.')
 end
 
 total_report = "Looking for doctests in a total of #{ruby_file_names.length} possible files\n"
 total_files, total_tests, total_succeeded, total_failed = 0, 0, 0, 0
 ruby_file_names.each do |ruby_file_name|
   tests, succeeded, failed, report = runner.process_ruby_file(ruby_file_name)
   total_files += 1 if tests > 0
   total_tests += tests
   total_succeeded += succeeded
   total_failed += failed
   total_report << report << "\n" unless report.empty?
 end
 total_report << "Total files: #{total_files}, total tests: #{total_tests}, assertions succeeded: #{total_succeeded}, assertions failed: #{total_failed}"
 puts total_report
end

