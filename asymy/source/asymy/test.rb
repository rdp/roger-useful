#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'pp'
require 'asymy'

EventMachine::run {
    c = Asymy::Connection.new(:target => "localhost",
                              :port => 3306,
                              :username => "dummy",
                              :password => "pass",
                              :database => "test")
    c.exec("select * from edges") do |x, y|
        pp x
        pp y
    end
}
