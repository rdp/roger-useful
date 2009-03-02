# Micro pause
# A utility designed to force you to take breaks every so often
# From your computer.
# It does this by you tell it how often you'd like a breather.
# It pops up a breather during that time for X s.
# It's a freeware competitor to break reminder.
# Built using Ruby's shoes toolkit.
# 
# MIT License (c) Roger Pack 2009
# Looks like there's plenty of competition:
# http://break.qarchive.org/
# but probably not too much written for shoes

Shoes.app :height => 200, :width => 200 do
  para "Enter how many minutes before you'd like to take a micro pause?"
  a = edit_line('3') do |e|
     @counter.text = e.text.to_i.to_s
  end
  @counter = strong(a.text)
  b = para "every ", @counter, " minutes pause for "

  c = edit_line('20') { |e| }

  d = para "s"
  button "select" do
    @@interval = a.text.to_f
    @@pause_time = c.text.to_f
    Shoes.debug @@interval
    @@spawner = self
    @@shared = Module.new
    self.class.class_eval { include @@shared }
    @@shared.module_eval {
     def restart
     
     timer(@@interval) do
      window :width => 1000, :height => 1000 do
        para "yo yo sleepy sleepy " + @@pause_time.to_s + "s!" 
        timer(@@pause_time) do
          @@spawner.restart  # has to be before close. Odd.
          close
        end
      end
     end
     end
    }
    restart
    #close # odd
    
  end
    
end
