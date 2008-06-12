require 'rubygems'
require 'eventmachine'
require 'asymy'
require 'pp'

EventMachine::run {
   c = Asymy::Connection.new(:target => "localhost",
                             :port => 3306,
                             :username => "root",
                             :password => "",
                             :database => "wilkboar_ties")

   c.exec("show databases") do |fields, rows|
       pp fields
       pp rows
   end
}
