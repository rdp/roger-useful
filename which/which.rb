  puts 'syntax: binary_name'
  def which ( bin )
    success = false
    puts bin if File::executable? bin

    path = ENV['PATH'] # || ENV['WHAT_EVER_WINDOWS_PATH_VAR_IS']
    path.split(File::PATH_SEPARATOR).each do |dir|
      candidate = File::join dir, bin.strip
      if File::executable? candidate
         puts candidate
         success = true
      end
    end

    # This is an implementation that works when the which command is
    # available.
    # 
    # IO.popen("which #{bin}") { |io| return io.readline.chomp }

    return success
  end 
  answer = which(ARGV[0])
  # windows compat.
  if !answer and RUBY_PLATFORM =~ /mswin|mingw/
    which(ARGV[0] + '.exe')
    which(ARGV[0] + '.bat')
    which(ARGV[0] + '.cmd')
  end
