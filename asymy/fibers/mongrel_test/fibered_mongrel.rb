module Mongrel
        class MongrelProtocol
        alias :old_receive_data :receive_data

def receive_data data
                # not sure how much of the data processing is actually 'processing that could block on IO, like for DB calls -- so just
                # surround the whole thing, for now, since a few extra fiber creations don't seem to hurt too much
fiber_for_this_round = Fiber.new {
        print "NEW FIBER\n"
        old_receive_data data
}
fiber_for_this_round.resume # returns and execution continues from here, if nothing
# special happens.  If something special does happen [like it renders a web page]# then non-blocking DB adapters will call Fiber.return_control
# when they block, which allows this one to continue.  Those fibers
# will be 'continued' once their blocking IO returns.
end


end
end

