# file which writes to the disk then gives you some metrics back as to how long it took
# meant as a freeware competitor to HD Tach
def println *args
 print *args
 print "\n" unless args[-1].to_s[-1] == "\n"
end
 
require 'benchmark'
filesize = 100_000_000
println 'write ', filesize
println Benchmark.realtime {
a = File.new 'tempy', 'w'
a.seek filesize
a.write 'a'
a.close
}
File.delete 'tempy'

file_count = 10_000
println 'write ', file_count.to_s, ' files'
p Benchmark.realtime {
file_count.times { |n|
 a = File.new n.to_s, 'w'
 a.write 'b'
 a.close
} 
}
println 'delete ' + file_count.to_s + ' files'
p Benchmark.realtime {
file_count.times { |n|
File.delete n.to_s
} 
}
