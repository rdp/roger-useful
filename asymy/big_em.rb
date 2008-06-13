require 'rubygems'
require 'eventmachine'
require 'source/asymy/asymy'
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
                        check_if_can_run # seems to work with a large pool--we'll call it good
                }
#		check_if_can_run # not sure if this is necessary ever or not...
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

# non pool
conns = []
20.times {conns << Asymy::Connection.new(opts) } 
outstanding = 0

0.upto(10) do |i|
   outstanding += 1
   conns[i].exec("select COUNT(*) from user_sessions") {|cols, rows| pp 'big', [i, rows.size]
	outstanding -= 1
	EM.stop if outstanding == 0
	}
end

# pool
pool = ConnectionPool.new 10, opts
10.times { |i|
  outstanding += 1
  pool.exec_when_available("select COUNT(*) from users") {|cols, rows|
        pp 'small', [i, rows.size]
	outstanding -= 1
	EM.stop if outstanding == 0

  }
}

} # EM run
