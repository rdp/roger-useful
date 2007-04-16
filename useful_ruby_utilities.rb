#Roger Pack

# to use  require "useful_ruby_utilities"

class AssertionFailure < StandardError # from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/41639
end

class Object
  def assert(bool, message = 'assertion failure')
      # this means 'if the -d command passed to ruby-- we don't use that every right now...if $DEBUG
                raise AssertionFailure.new(message) unless bool
                    end
  #end
end

require 'socket' # gotta override a previously instantiated socket!
class Socket
        class << self
        def gethostip
                return getHostIP
        end
        def getHostIP
            ipInt = gethostbyname(gethostname())[3]
            return "%d.%d.%d.%d" % [ipInt[0], ipInt[1], ipInt[2], ipInt[3]]
        end
        end
end

class Object

 def methodLookup(methodName)
    classname = self.class
    
    if classname == "Class" # then methodLookup is being called on a class itself, ala "String.methodLookup(x)" instead of "stringInstance.methodLookup(x)"
        classname = self.name
   end
   result  = system("ri.bat \"%s.%s\" --no-pager" % [classname, methodName]) # only works in windows, here
   if not result
       result  = system("ri \"%s.%s\" --no-pager" % [classname, methodName]) # may work better in linux
   end
   return result
   end

end # Object

def writeToFile(a)
  return File.new(a, "w")
end

def readFromFile(b)
  return File.new(b, "r")
end

class Fixnum
 def asIfChar
  return "%c" % self
 end
end

# and its opposite--kind of -- a very broken string to ascii
class String
 def firstCharToAscii
        return ("%d" % self[0]).to_i
 end

 def firstCharToBinary
        return  "%b" % firstCharToAscii()
 end
end

class Hash
def greatestValue
 greatestValue = nil
  self.each_pair do |key, value|
     if greatestValue == nil or value > greatestValue[1] # todo more fast!
                greatestValue = [key, value]
                   end
                    end
                     return greatestValue
                     end
                     end
                     


class TCPsocket

def writeReliable(stuffIn)
  totalToSend = stuffIn.length
  totalSent = 0
  while totalSent < totalToSend do
      if totalSent > 0
          print "writeReliable looped!!!!i once you see this once then mark it as useful, comment out"
      end
      received = write(stuffIn)
      stuffIn = stuffIn[received..10000000] # todo find a better way :)
      totalSent += received
  end
  flush
end
end

