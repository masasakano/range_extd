# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{range_extd}
  s.version = "0.3.0"
  # s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  # s.executables << 'hola'
  # s.bindir = 'bin'
  s.authors = ["Masa Sakano"]
  s.date = %q{2014-05-02}
  s.summary = %q{RangeExtd - Extended Range class with exclude_begin and open-ends}
  s.description = %q{Package for a subclass of Range, RangeExtd and RangeExtd::Infinity.  The former defines a range that enables an exclusion of the begin boundary, in addition to the end boundary as in the built-in Range, and accepts open-ended ranges to infinity for either (or both) positive/negative direction.  The latter has the two constant objects, POSITIVE and NEGATIVE, and they are a generalised Infinity of Float::INFINITY to any Comparable objects.}
  # s.email = %q{abc@example.com}
  s.extra_rdoc_files = [
    # "LICENSE",
     "README.en.rdoc",
     "README.ja.rdoc",
  ]
  s.license = 'MIT'
  s.files = [
    #".document",
     #".gitignore",
     #"VERSION",
     "News",
     "ChangeLog",
     "README.en.rdoc",
     "README.ja.rdoc",
     "Rakefile",
     "range_extd.gemspec",
     "lib/range_extd/range_extd.rb",
     "lib/range_extd/infinity/infinity.rb",
     "test/test_range_extd.rb",
  ]
  # s.add_runtime_dependency 'library', '~> 2.2', '>= 2.2.1'	# 2.2.1 <= Ver < 2.3.0
  # s.add_development_dependency "bourne", [">= 0"]
  # s.homepage = %q{http://}
  s.rdoc_options = ["--charset=UTF-8"]
  # s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.0'
  s.test_files = [
     "test/test_range_extd.rb",
  ]
  # s.test_files = Dir.glob('test/tc_*.rb')
  # s.requirements << 'libmagick, v6.0'	# Simply, info to users.
  # s.rubygems_version = %q{1.3.5}	# This is always set automatically!!

end

