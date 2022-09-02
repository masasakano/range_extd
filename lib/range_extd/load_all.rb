# -*- encoding: utf-8 -*-

req_files = %w(../range_extd infinity nowhere nil_class numeric object)
req_files.each do |req_file|
  begin
    require_relative req_file 
  rescue LoadError
    require req_file 
  end
end

if $DEBUG
  puts "NOTE: Library full paths:"
  req_files.each do |elibbase|
    ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(File.basename(elibbase))}(\.rb)?$/).uniq
    print elibbase+": " if ar.empty?; p ar
  end
end

