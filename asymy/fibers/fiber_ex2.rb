# this used to be an example file for using renamed fiber methods, which are now no longer used 
var = nil

fib = Fiber.new {
  Fiber.yield 3
}

a = fib.resume
print 'a is', a
