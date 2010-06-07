file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(file))

require File.join(this_dir,'lib/connection')
require File.join(this_dir,'lib/terminal')
require File.join(this_dir,'lib/sms')

require 'rubygems'

