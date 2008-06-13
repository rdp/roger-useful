# this just makes sure that evented mongrel is working
# start it, then wget http://localhost:3000/test should work :)

require 'rubygems'
require 'swiftcore/evented_mongrel'
#require 'mongrel'
require '../../source/asymy/asymy'
require '../setup_db_opts'

 class SimpleHandler < Mongrel::HttpHandler
    def process(request, response)
      response.start(200) do |head,out|
        head["Content-Type"] = "text/plain"
        out.write("hello!\n")
      end
    end
 end

 h = Mongrel::HttpServer.new("0.0.0.0", 3000)
 h.register("/test", SimpleHandler.new)
 h.register("/files", Mongrel::DirHandler.new("."))
 h.run.join
