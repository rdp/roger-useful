# this file just shows how fibers interleave -- an example of how to use resume and yield

var = nil

fib = Fiber.new {
  Fiber.yield 3

}
a = fib.resume
#print 'a is', a
main_fiber = Fiber.new {


var = nil
fib = Fiber.new {
  var = 44
  print 'here1'
  Fiber.yield#fib.resume
  print 'here3'
  Fiber.yield 3
}

a = fib.resume
print 'here2'
 print 'a is', a, 'var is', var
fib.resume
print 'here4'



}.resume
