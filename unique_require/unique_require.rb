# unique require for ruby 1.8.x
# see README
require 'pathname'
module Kernel
        alias :original_require :require
        def require *args
                filename = args[0]
                for dir in ['.'] + $:
                        for file in Dir.glob "#{dir}/#{filename}*"
				if file =~ /#{filename}||.rb|.so|.bundle/
				  return original_require(Pathname.new(file).realpath)
				end
                        end
                end unless filename == 'pathname' # let that one pass, to avoid problems
                original_require *args
        end
end

# doctest: it should require files only once
# >> require 'pathname'
# >> $a = 1
# >> File.open('require_once.rb', 'w') do |f|; f.write '$a += 1'; end # write out a file that increments $a
# >> require 'require_once.rb'
# >> $a
# => 2 # it should increment it once
# >> parent_dir = File.dirname( Pathname.new($0).expand_path ).split('/')[-1]
# >> require "../#{parent_dir}/require_once.rb"
# >> $a
# => 2 # but not a second time

