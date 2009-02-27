# Micro pause
# A utility designed to force you to take breaks every so often
# From your computer.
# It does this by you tell it how often you'd like a breather.
# It pops up a breather during that time for 20s.
# It's a freeware competitor to break reminder.
# Built using Ruby's shoes toolkit.
# 
# MIT License (c) Roger Pack 2009
#

Shoes.app :height => 200, :width => 200 do
  para "Enter how many minutes before you'd like to take a micro pause?"
  a = edit_line do |e|
     @counter.text = e.text.to_i.to_s
  end
  @counter = strong("0")
  para @counter, " minutes"
  button "select" do
    @@interval = a.text.to_i
    Shoes.debug @@interval
    timer(@@interval) do
      window :width => 1000, :height => 1000 do
        para "yo yo sleepy sleepy 20s!" 
        timer(5) do
          close
        end
      end
    end
    
  end
    
end
