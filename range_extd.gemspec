# -*- encoding: utf-8 -*-

require 'rake'
require 'date'

Gem::Specification.new do |s|
  s.name = %q{range_extd}.sub(/.*/){|c| (c == File.basename(Dir.pwd)) ? c : raise("ERROR: s.name=(#{c}) in gemspec seems wrong!")}
  s.version = "2.0".sub(/.*/){|c| fs = Dir.glob('changelog', File::FNM_CASEFOLD); raise('More than one ChangeLog exist!') if fs.size > 1; warn("WARNING: Version(s.version=#{c}) already exists in #{fs[0]} - ok?") if fs.size == 1 && !IO.readlines(fs[0]).grep(/^\(Version: #{Regexp.quote c}\)$/).empty? ; c }  # n.b., In macOS, changelog and ChangeLog are identical in default.
  # s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  # s.executables << 'hola'
  # s.bindir = 'bin'
  s.authors = ["Masa Sakano"]
  s.date = %q{2022-09-08}.sub(/.*/){|c| (Date.parse(c) == Date.today) ? c : raise("ERROR: s.date=(#{c}) is not today!")}
  s.summary = %q{RangeExtd - Extended Range class with exclude_begin and open-ends}
  s.description = %q{Package for a subclass of Range, RangeExtd, containing RangeExtd::Infinity and RangeExtd::Nowhere. RangeExtd defines ranges that enable an exclusion of the begin boundary, in addition to the end boundary as in the built-in Range, and accepts open-ended ranges to infinity for either (or both) positive/negative direction.  The open-ended boundaries are represented by two constant objects, POSITIVE and NEGATIVE of RangeExtd::Infinity, and they are a generalised Infinity of Float::INFINITY to any Comparable objects, which are in practice similar to built-in beginless/endless Ranges.}
  # s.email = %q{abc@example.com}
  s.extra_rdoc_files = [
    # "LICENSE",
     "README.en.rdoc",
     "README.ja.rdoc",
  ]
  s.license = 'MIT'
  s.files = FileList['.gitignore','lib/**/*.rb','[A-Z]*', 'test/**/*.rb'].to_a.delete_if{ |f|
    ret = false
    arignore = IO.readlines('.gitignore')
    arignore.map{|i| i.chomp}.each do |suffix|
      if File.fnmatch(suffix, File.basename(f))
        ret = true
        break
      end
    end
    ret
  }
  s.files.reject! { |fn| File.symlink? fn }

  # s.add_runtime_dependency 'library', '~> 2.2', '>= 2.2.1'	# 2.2.1 <= Ver < 2.3.0
  # s.add_development_dependency "bourne", [">= 0"]
  s.homepage = %q{https://www.wisebabel.com}
  s.rdoc_options = ["--charset=UTF-8"]

  # s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.7'
  s.test_files = Dir['test/**/*.rb']
  s.test_files.reject! { |fn| File.symlink? fn }
  # s.requirements << 'libmagick, v6.0'	# Simply, info to users.
  # s.rubygems_version = %q{1.3.5}	# This is always set automatically!!

  s.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.
end

