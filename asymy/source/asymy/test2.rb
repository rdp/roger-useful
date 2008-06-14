#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'pp'
require 'asymy'

EventMachine::run {
    c = Asymy::Connection.new(:target => "localhost",
                              :port => 3306,
                              :username => "root",
                              :password => "",
                              :database => "local_leadgen_dev")
    c.exec("select * from users") do |x, y|
        pp x
        pp y
    end
    require 'ruby-debug'
	debugger
	3
}
