#Roger Pack
require 'pp'
# to use  require "useful_ruby_utilities"

class AssertionFailure < StandardError # from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/41639
end

def goGetFile(urlToGet, whereItGoes = nil)
    wgetCommand = "wget #{urlToGet}"
    if whereItGoes
      wgetCommand += " -O #{whereItGoes}"
    end
   # todo double check this, see if wget exists, etc...
    system(wgetCommand)
    # lodo add the ruby way in here :)
end

def isGoodExecutableFile?(thisFileName)
  if File.executable_real? thisFileName
    return true
  end
 begin
    a = IO.popen(thisFileName, "w+")
    returnVal = true
    # if that cleared then the exec worked
    a.close
 rescue => details
  returnVal = false
 end
 return returnVal # lodo there's some bug with this
end


class String
def shiftOutputAndResulting number
  output = self[0..(number -1)]
  rest = self[number..10000000]
  if rest != nil and rest.length == 0
    rest = nil
  end
  return output, rest # lodo better funcs

end
end


class Object
  def assert(bool, message = 'assertion failure')
      # this means 'if the -d command passed to ruby-- we don't use that every right now...if $DEBUG
                if not bool
                  print "ack assertion failed! [#{message}]\n"
                  begin
                    raise AssertionFailure.new(message)
                  rescue AssertionFailure => a
                    print a.backtrace.join("\n")
                    print "\n"
                    raise
                  end
               end
  end
end

def assertEqual(a, b, errorString = "")
        if a != b
            message = "ERROR NOT EQUAL: [" + a.to_s + "] != [" + b.to_s + "]\n"
            print message
            pp a, "!=", b
            raise AssertionFailure.new(message)
        end
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


class TCPSocket
          attr_accessor :amPastHeader 

          def nukeHeaderAndSetBoolIfThere(fromThis)
              locationOfSplit = fromThis.index("\r\n\r\n")
              if locationOfSplit != nil
                    self.amPastHeader = true
                    returnable = fromThis[locationOfSplit + 4..1000000] # what a hack!
                    print "returning #{returnable}"
                    return returnable
              else
                    print "very odd! -- [#{fromThis}] must be in the header still!"
                    return ""
                    
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

  def multiplyKeysBy(this)
    output = {}
    self.each_key { |key|
      output[key * this] = self[key]
    
    }
    return output
  end
  def keysToInts
    output = {}
    self.each_key { |key|
      output[key.to_i] = self[key]
    
    }
    return output
  
  end

  def sumValues
   sum = nil
   self.each_key { |key|
    if not sum.nil?
      sum += self[key]
    else
      sum = self[key] # keep this non class specific :)
    end
   
   }
   return sum
  end

  def addToKey(key, addThis)
    if self.has_key? key
      self[key] += addThis
    else
      self[key] = addThis
    end
  end
  
  def keyValueOrZero key
    if self.has_key? key
      return self[key]
    else
      return 0
    end
  end


 def pairWithGreatestKey # same as max but doesn't err... todo report!
 greatestKeyPair = nil
 self.each_pair do |key, value|
     if greatestKeyPair == nil or key > greatestKeyPair[0] # todo more fast!
       greatestKeyPair = [key, value] # to be able to pass them both out
     end
  end
 return greatestKeyPair
 end

def greatestValue

 greatestValue = nil
  self.each_pair do |key, value|
     if greatestValue == nil or value > greatestValue[1] # todo more fast!
                greatestValue = [key, value]
                   end
                    end
                     return greatestValue
                   end
                   
  def ifOrderedSumOfValuesUpToAndIncludingKey(maxKey)
    sum = 0
    # self.sort is an array of pairs [[key, value], [key, value]...]
    for key, value in self.sort do 
      if key > maxKey
          break
        end
      sum += value
    end
    return sum
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
  end# todo test!
  flush
end
end

# code for exception handling
#    begin
#      go(bm)
#   rescue  => detail
#     print detail.backtrace.join("\n")
#   end

# code for threading
# return Thread.new(bm) { |bm|

#    begin
#      startClient(fullUrl, bm)
#   rescue  => detail
#     print detail.backtrace.join("\n")
#   end
# }
#
# return Thread.new(bm) { |bm|
#      startClient(fullUrl, bm)
# }


class Float

  def truncateToDecimal(decimal)
    return ("%.0#{decimal}f" % self).to_f
  end
end # class

class Array
    def joinOnAllThreadsInArray
      while not self.empty?
       waitForThisThread = self.shift
       assert waitForThisThread.class == Thread
       waitForThisThread.join
      end
    end
    
    def collapsePointsToIntegers
      return toSummedByIntegerHash.sort
    end
    
   def toSummedByIntegerHash # lodo rename sum
      finalArray = {}
      self.each { |pointDuple|
        finalArray.addToKey(pointDuple[0].to_i, pointDuple[1])
      }
      return finalArray
   end
   
   def dupleArrayToSummedHash
      finalArray = {}
      self.each { |pointDuple|
        finalArray.addToKey(pointDuple[0], pointDuple[1])
      }
      return finalArray
    
   end
   
def average
  sum = 0
  self.each { |entry|
   sum += entry
  }
  return sum / self.length
end
  


 # from http://snippets.dzone.com/posts/show/898
  # Chooses a random array element from the receiver based on the weights
  # provided. If _weights_ is nil, then each element is weighed equally.
  # 
  #   [1,2,3].random          #=> 2
  #   [1,2,3].random          #=> 1
  #   [1,2,3].random          #=> 3
  #
  # If _weights_ is an array, then each element of the receiver gets its
  # weight from the corresponding element of _weights_. Notice that it
  # favors the element with the highest weight.
  #
  #   [1,2,3].random([1,4,1]) #=> 2
  #   [1,2,3].random([1,4,1]) #=> 1
  #   [1,2,3].random([1,4,1]) #=> 2
  #   [1,2,3].random([1,4,1]) #=> 2
  #   [1,2,3].random([1,4,1]) #=> 3
  #
  # If _weights_ is a symbol, the weight array is constructed by calling
  # the appropriate method on each array element in turn. Notice that
  # it favors the longer word when using :length.
  #
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "hippopotamus"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "dog"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "hippopotamus"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "hippopotamus"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "cat"
  def randomItem(weights=nil)
    return random(map {|n| n.send(weights)}) if weights.is_a? Symbol
    
    weights ||= Array.new(length, 1.0)
    total = weights.inject(0.0) {|t,w| t+w}
    point = rand * total
    
    zip(weights).each do |n,w|
      return n if w >= point
      point -= w
    end
  end
  
  # Generates a permutation of the receiver based on _weights_ as in
  # Array#random. Notice that it favors the element with the highest
  # weight.
  #
  #   [1,2,3].randomize           #=> [2,1,3]
  #   [1,2,3].randomize           #=> [1,3,2]
  #   [1,2,3].randomize([1,4,1])  #=> [2,1,3]
  #   [1,2,3].randomize([1,4,1])  #=> [2,3,1]
  #   [1,2,3].randomize([1,4,1])  #=> [1,2,3]
  #   [1,2,3].randomize([1,4,1])  #=> [2,3,1]
  #   [1,2,3].randomize([1,4,1])  #=> [3,2,1]
  #   [1,2,3].randomize([1,4,1])  #=> [2,1,3]
  def randomizedCopy(weights=nil)
    return randomize(map {|n| n.send(weights)}) if weights.is_a? Symbol
    
    weights = weights.nil? ? Array.new(length, 1.0) : weights.dup
    
    # pick out elements until there are none left
    list, result = self.dup, []
    until list.empty?
      # pick an element
      result << list.randomItem(weights)
      # remove the element from the temporary list and its weight
      weights.delete_at(list.index(result.last))
      list.delete result.last
    end
    
    result
  end
  
  def eachInRandomOrderWithIndex
   arrayOfNumbersRepresentingUnchosenLocations = (0..(self.length - 1)).to_a
   while arrayOfNumbersRepresentingUnchosenLocations.length > 0
     indexIntoArrayOfUnchosenNumbers = rand(arrayOfNumbersRepresentingUnchosenLocations.length) # rand  index 
     newRandomNumber = arrayOfNumbersRepresentingUnchosenLocations.slice!(indexIntoArrayOfUnchosenNumbers, 1)[0] # slice it out
     yield self[newRandomNumber], newRandomNumber
   end
  end
  
  
end
