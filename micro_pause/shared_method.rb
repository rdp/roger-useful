
Shoes.app do
 @@shared = Module.new
 self.class.class_eval { include @@shared }

 @@shared.module_eval { 
   def shared_method
     Shoes.debug('in shared method')
   end
 }
  
 shared_method
 window do
  shared_method
 end
end
