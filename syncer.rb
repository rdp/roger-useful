#!/Users/roger/ppc_local/bin/ruby -w
# this program syncs between two database tables to make a recipient match a donor table
# so the question still remains--does navicat maintain 'id' integrity on inserts?  Should we?
# note this lacks 'transaction's thus far
# and its SSH is hackish
# TODO sql escape things better (does it a little already)
# TODO could use a 'mass insert' to speed things up (one giant giant string), or...that rails plugin that does the same.  If that hurts then maybe some 'O(1) string' (if).
# could do: something along the lines of rsync for database tables--calculate some checksums, foreign host, etc., anything to save on bandwidth lol. It is, however, true that most changes come from the "latter end" of tables so...probably has tons of potential savings
# could do: download the next table while you're comparing the first muhaha
# TODO handle ssh => ssh
# could do: download from both people at the same time, per table, or what not muhaha
# could do: some more free's in here
# could do: at the beginning verify all tables exist on from, to databases, and all have the same structure
# could do: at the end output 'just the summary' (and the to, from db's)
# could do: timings per table

  require 'optparse'
 
  # define some databases and how you connect with them, if foreign
  mac = {:host => '127.0.0.1', :user => 'root', :password => '', :db => 'local_leadgen_dev', :ssh_host => nil}
# define more here!
  db_from_info = mac
  db_to_info = production


  actually_run_queries = false
  my_options = {}
  default_tables_to_sync_if_none_passed = ['programs']
  tables_to_sync = []
  verbose = true # default
  # make sure they used options
  raise 'poor parameter use -- expected first parameter to start with a -' if ARGV.length > 0  and ARGV[0][0..0] != '-'
  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    opts.on("-f", "--from=FROM", "from setting") do |from_name|
      print "using from #{from_name}\n"
      eval("db_from_info = #{from_name}")
    end

    opts.on("-e", "--to=TO", "to setting") do |to_name|
	print "using db TO #{to_name}\n"
        eval("db_to_info = #{to_name}")
    end

    opts.on("-t", "--tables=", "tables list", Array) do |tables|
      for entry in tables do
        print 'doing table', entry, ' '
  	tables_to_sync << entry
      end
    end

    opts.on("-commit", "--commit", " tell us whether or not to actually run queries") do
      print "DOING IT COMMITTING LIVE QUERIES\n"
      actually_run_queries = true
    end

    opts.on("-z", "--extra_sql=STRING", "run this sql") do |sql|
      print "extra sql", sql
      my_options[:extra_sql] = sql
    end
  end.parse!

  tables_to_sync = default_tables_to_sync_if_none_passed if tables_to_sync.empty? # allow for the defaults
  raise if db_to_info == production and actually_run_queries # I never wanted to commit to one db
  raise unless db_from_info and db_to_info
  raise if actually_run_queries and db_to_info == production

  require 'rubygems'
  require "mysql"

class Hash
	def to_sql_update_query(table_name, nonmatching_keys) # ltodo take some 'params' :)
		raise unless self['id']
		query = "update #{table_name} set"
 		comma = ''
		self.each_key do |key|
			query << "#{comma} #{key} = #{self[key] ? "'" + self[key].gsub("'", "\\\\'") + "'": 'NULL'}" if nonmatching_keys.include? key
			comma = ',' if nonmatching_keys.include? key
		end
		query << " where id = #{self['id']}"
	end

	def to_sql_create_query(table_name)
		query = "insert into #{table_name} ("
		comma = ''
		self.each_key { |key_name|
			query += "#{comma}#{key_name} "
			comma = ','
		}
		query += ") values ( "
		comma = ''
		self.each_key { |key_name|
			query += "#{comma} #{self[key_name] ? "'" + self[key_name].gsub("'", "\\\\'") + "'" : 'NULL'}" # assume it will leave the others are null, I guess
			comma = ','
		}
	 	query += ");"
	end		
end
   

   if db_from_info[:ssh_host]
		db_from_info[:host] = '127.0.0.1'
		db_from_info[:port] = 4000
   end

   if db_to_info[:ssh_host]
		db_to_info[:host] = '127.0.0.1'
		db_to_info[:port] = 4000
   end
   print "\n#{db_from_info[:ssh_host] || db_from_info[:host]}:#{db_from_info[:db]} #{tables_to_sync.inspect}\n"
   print "\t=> #{db_to_info[:ssh_host] || db_to_info[:host]}:#{db_to_info[:db]} #{tables_to_sync.inspect}\n"
   
   commit_style = actually_run_queries ? '---COMMITTING----' : 'previewing (no changes made)'
   print "#{commit_style} run"
   start_time = Time.now 
   begin
     # connect to the MySQL server
     print 'connecting to to DB...', "\n"
     db_to = Mysql.real_connect(db_to_info[:host], db_to_info[:user], db_to_info[:password], db_to_info[:db], db_to_info[:port], nil, Mysql::CLIENT_COMPRESS)
     print 'connected to To DB, now connecting to from DB ', "\n"
     db_from = Mysql.real_connect(db_from_info[:host], db_from_info[:user], db_from_info[:password], db_from_info[:db], db_from_info[:port], nil, Mysql::CLIENT_COMPRESS)
     print "connected to From DB \n"
   rescue Mysql::Error => e
     puts "Error code: #{e.errno}"
     puts "Error message: #{e.error}"
     puts "This may mean a tunnel is not working" if e.error.include?('127.0.0.1')
     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
     print "Did you forget to start this ssh tunnel?"
     if db_from_info[:ssh_host] or db_to_info[:ssh_host]
		print "please run this in another screen:\n" # assumes that we only have one ssh host, in from. redo if this doesn't hold
	print "ssh -L 4000:localhost:3306 #{db_from_info[:ssh_user] || db_to_info[:ssh_user]}@#{db_from_info[:ssh_host] || db_to_info[:ssh_host]} \n" # NOTE DOES NOT YET ALLOW FOR TWO SSH DB's
     end
     exit
   ensure
     # disconnect from server here :)
   end

  summary_information = '' # so we can print it all (again), at the end

  for table in tables_to_sync  do
   print "start #{commit_style} table #{table}" + "**" * 10 + "\n"
   all_to_keys_not_yet_processed = {}
   select_all_to = db_to.query("SELECT * FROM #{table}") # could easily be 'select id', as well note this assumes distinct id's! Otherwise we'd need hashes, one at a time, etc. etc.
   select_all_to.each_hash { |to_element|
	raise if all_to_keys_not_yet_processed[to_element['id']] # duplicated id's are a fringe case and not yet handled!
	all_to_keys_not_yet_processed[to_element['id']] = to_element
   }

   res = db_from.query("SELECT * from #{table}")
   count_updated = 0
   count_created = 0
   
   res.each_hash do |from_element|
	existing = all_to_keys_not_yet_processed[from_element['id']]
	# now there are a few cases--we can find a matching id->rest locally, or an id->nonmatching (update) or non_id (insert)
	# the problem is that we need to keep track of which id's we never used, and delete them from the offending table, afterward
	if existing # we have a match--test if it is truly matching
		to_element = existing# ltodo rename
		all_nonmatching_keys = []
		for key in from_element.keys do
			if from_element[key] != to_element[key]
				all_nonmatching_keys << key
				print ' [', from_element[key], "]!=[", to_element[key]||'',  ']', "\n" if verbose
			else
				# equal, ok
			end

		end
		if all_nonmatching_keys.length > 0
			count_updated += 1
			query = from_element.to_sql_update_query(table, all_nonmatching_keys)
			print "update query on #{to_element['name']}: #{query}\n" if verbose
			db_to.query query if actually_run_queries
		end
	else
		count_created += 1
		create_query = from_element.to_sql_create_query(table)
		print "insert query on #{from_element['name']}: #{create_query}\n" if verbose
		db_to.query create_query if actually_run_queries
        end
	all_to_keys_not_yet_processed.delete(from_element['id'])
   end
   print "\n" if (count_updated>0 or count_created>0) if verbose


   count_deleted = all_to_keys_not_yet_processed.length
   if count_deleted > 0
     ids = []
     for id in all_to_keys_not_yet_processed.keys do
       ids << id 
     end
     double_check_all_query = "select * from #{table} where id IN (#{ids.join(',')})" # this allows us to make sure we don't delete any doubled ones (which would be a weird situation and too odd to handle), and also so we can have a nice verbose  'we are deleting this row' message
     double_check_result = db_to.query double_check_all_query

     raise 'weird deleted--got back strange number of rows -- refusing to delete' unless double_check_result.num_rows == count_deleted

     victims = {}

     double_check_result.each_hash {|victim|
        raise 'duplicate' if victims[victim['id']]
        victims[victim['id']] = victim['name']
     }
     for id in all_to_keys_not_yet_processed.keys do
       query = "delete from #{table} where id = #{id}"
       print "DELETE query, for #{victims[id]} is #{query}\n" if verbose
       db_to.query query if actually_run_queries
     end
   end

   res.free
   print "done #{commit_style} "
   summary =  "#{table} -- updated #{count_updated}, created #{count_created}, deleted #{count_deleted}\n"
   print summary
   summary_information << summary
  end
  if my_options[:extra_sql] and actually_run_queries
    print "doing sql #{my_options[:extra_sql]}\n"
    result = db_to.query my_options[:extra_sql]
    require 'pp'
    pp "got sql result", result 
  end
  db_from.close if db_from
  db_to.close if db_to
  print "summary:---------------------------#{commit_style}'ed\n", summary_information
  print "total time #{Time.now - start_time}"
