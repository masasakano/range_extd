# -*- encoding: utf-8 -*-

$stdout.sync=true
$stderr.sync=true
# print '$LOAD_PATH=';p $LOAD_PATH
arlibbase = %w(range_extd range_extd/nowhere.rb)	# range_extd/nowhere.rb is actually loaded from range_extd.  But by writing here, the absolute path will be displayed.

arlibrelbase = arlibbase.map{|i| "../lib/"+i}

arlibrelbase.each do |elibbase|
  require_relative elibbase
end

print "NOTE: Library relative paths: "; p arlibrelbase
print "NOTE: Library full paths:\n"
arlibbase.each do |elibbase|
  ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(File.basename(elibbase))}(\.rb)?$/).uniq
  print elibbase+": " if ar.empty?; p ar
end


#################################################
# Unit Test
#################################################

require 'rational' if !defined?(Rational) # For Ruby 1.8

gem "minitest"
require 'minitest/autorun'

class TestUnitNowhere < MiniTest::Test
  T = true
  F = false

  def setup
  end

  def teardown
  end

  def test_nowhere
    nowhere = RangeExtd::Nowhere::NOWHERE
    assert(RangeExtd::Nowhere.instance.eql?(nowhere), "Const.id=#{RangeExtd::Nowhere::NOWHERE.__id__} nowhere.id=#{nowhere.__id__}; nil=#{RangeExtd::Nowhere::NOWHERE.nil?.inspect}=#{nowhere.nil?.inspect}; nowhere?=#{RangeExtd::Nowhere::NOWHERE.nowhere?.inspect}=#{nowhere.nowhere?.inspect}; hash=#{RangeExtd::Nowhere::NOWHERE.hash}=#{nowhere.hash}")
    refute(nowhere.eql?(nil))
    assert( nowhere == nil )
    assert_equal 0, ( nowhere <=> nil )

    assert nowhere.nowhere?
    assert_equal RangeExtd::Nowhere, nowhere.class_raw
    assert_equal NilClass,           nowhere.class

    assert( nowhere )  # Unfortunately, there is no way in Ruby to make the object behave like false/nil in the conditional statement: see <https://stackoverflow.com/a/14449380/3577922>
    assert( nowhere.nil? )
  end	# def test_nowhere

  # 'nil_class.rb' is always required, and so these should hold.
  def test_nil_class
    nowhere = RangeExtd::Nowhere::NOWHERE
    refute(nil.eql?(nowhere))
    assert( nil == nowhere )
    assert_equal 0, ( nil <=> nowhere )

    refute nil.nowhere?
    assert_equal NilClass, nil.class_raw
    assert_equal NilClass, nil.class
  end  # def test_nil_class

  ## when 'nil_class.rb' is not required, these are the cases.
  #def test_nil_class
  #  nowhere = RangeExtd::Nowhere::NOWHERE
  #  refute(nil.eql?(nowhere))
  #
  #  refute(     nil == nowhere )
  #  assert_nil( nil <=> nowhere )
  #
  #  refute nil.respond_to?(:nowhere?)
  #  refute nil.respond_to?(:class_raw)
  #  assert_equal NilClass, nil.class
  #end  # def test_nil_class
end # class TestUnitNowhere < MiniTest::Test

