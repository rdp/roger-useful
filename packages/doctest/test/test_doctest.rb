=begin
>> require 'doctest.rb'
=> true
>> runner = DocTest.new
=> #<DocTest:0x3b59c0>
>>    tests, succeeded, failed, report = runner.process_ruby_file(ruby_file_name)
NameError: undefined local variable or method `ruby_file_name' for main:Object
	from (irb):3
>>    tests, succeeded, failed, report = runner.process_ruby_file('test_tester.rb')
=> [3, 7, 0, "Processing 'test_tester.rb' from current directory \n Testing ''...OK\n Testing ''...OK\n Testing ''...OK"]
>> 
=end
