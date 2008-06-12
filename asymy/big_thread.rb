require 'rubygems'
require 'pp'
require 'mysql'
parent_thread = Thread.current


   begin
     # connect to the MySQL server
     #dbh = Mysql.real_connect("localhost", "wilkboar_ties", "ties", "local_leadgen_dev")
     conns = []
     22.times { conns << Mysql.real_connect("localhost", "wilkboar_ties", "ties", "local_leadgen_dev") }
     $outstanding = 15
      
     5.times {
	Thread.new(conns.shift) {|conn|
	 res = conn.query "select count(*) from user_sessions"
	 res.each_hash do |row|
     		printf "BIG: #{row.inspect},\n"
   	 end		
	 $outstanding -= 1
         parent_thread.wakeup if $outstanding == 0
	 print $outstanding, "\n"
	}
     }
     
    10.times {
	Thread.new(conns.shift) {|conn|
	 res = conn.query "select count(*) from users"
	 res.each_hash do |row|
     	      printf "small: #{row.inspect} ,\n"
   	 end		
	 $outstanding -= 1
         if $outstanding == 0
	 print "DONE"
	 parent_thread.kill
 	end
         print $outstanding, "\n"
	}
     }
     
     sleep
     # get server version string and display it
     puts "Server version: " + dbh.get_server_info
   rescue Mysql::Error => e
     puts "Error code: #{e.errno}"
     puts "Error message: #{e.error}"
     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
   ensure
     # disconnect from server
     #dbh.close if dbh
   end

=begin

EventMachine::run {
   opts = {:target => "localhost",
                             :port => 3306,
                             :username => "wilkboar_ties",
                             :password => "ties",
                             :database => "local_leadgen_dev"}

conns = []
22.times {conns << Asymy::Connection.new(opts) }

0.upto(10) do |i|
   conns[i].exec("select COUNT(*) from user_sessions") {|cols, rows| pp 'big', [i, rows.size]}
end

0.upto(10) do |i|
   conns[10+i].exec("select COUNT(*) from users") {|cols, rows|
pp 'small', [i, rows.size]}
end

}

=end

