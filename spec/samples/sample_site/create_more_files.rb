

require 'fileutils'


# get the last files created then create x number more

TO_COPY = "index2.html"

#Dir.entries(".").each do |e|
#  puts e
#end 

def copy_files(num_to_copy=50)
  new_file = TO_COPY
  start = 3
  (start..num_to_copy).each do |n|

    new_name = "page#{n}.html"
    FileUtils.cp TO_COPY, new_name, :verbose => true

  end
  

end

copy_files()
