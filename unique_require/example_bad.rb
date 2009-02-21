#
# run without arguments to display warning
# run with -runique_require to see it now not display the warning
#
require 'pathname'
require 'test'
parent_dir = File.dirname( Pathname.new($0).expand_path ).split('/')[-1]
require "../#{parent_dir}/test" # require it again
