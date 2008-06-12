require 'rubygems'
require 'eventmachine'
require 'asymy'
require 'pp'

class ConnectionPool
  def initialize count, opts
    @pool = []
    @waiting = []
    count.times { @pool << Asymy::Connection.new(opts) }
  end

  def check_if_can_run
	if @pool.length > 0 and @waiting.length > 0
		conn = @pool.shift
		query, block = @waiting.shift
		conn.exec(query) {|*args|
                        block.call *args
			@pool << conn
                        check_if_can_run
                }
	end
  end 

  def exec_when_available query, &block
	@waiting << [query, block]
	check_if_can_run
  end
end

EventMachine::run {
   opts = {:target => "localhost",
                             :port => 3306,
                             :username => "wilkboar_ties",
                             :password => "ties",
                             :database => "local_leadgen_dev"}

conns = []
11.times {conns << Asymy::Connection.new(opts) } 

pool = ConnectionPool.new 10, opts

0.upto(10) do |i|
   conns[i].exec("select COUNT(*) from user_sessions") {|cols, rows| pp 'big', [i, rows.size]}
end

1000.times { |i|
  pool.exec_when_available("select COUNT(*) from users") {|cols, rows|
     pp 'small', [i, rows.size]}
}

} # EM run
