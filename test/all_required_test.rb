# -*- encoding: utf-8 -*-

# tests for the case where all the files (to modify NilClass, Object etc) are required.

$stdout.sync=true
$stderr.sync=true
# print '$LOAD_PATH=';p $LOAD_PATH
arlibbase = %w(range_extd/load_all)  # require all in one go.

arlibrelbase = arlibbase.map{|i| "../lib/"+i}

arlibrelbase.each do |elibbase|
  require_relative elibbase
end

# But checking/displaying the required files individually.
arlibbase = %w(range_extd/nowhere range_extd/nil_class range_extd/object range_extd/numeric range_extd/range range_extd range_extd/infinity range_extd/load_all)
arlibrelbase = arlibbase.map{|i| "../lib/"+i}
print "NOTE: Running: "; p File.basename(__FILE__)
print "NOTE: Library relative paths: "; p arlibrelbase
arlibbase4full = arlibbase.map{|i| i.sub(%r@^(../)+@, "")}+%w(range_extd)
puts  "NOTE: Library full paths for #{arlibbase4full.inspect}: "
arlibbase4full.each do |elibbase|
  ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(File.basename(elibbase))}(\.rb)?$/)
  print elibbase+": " if ar.empty?; p ar
end


#################################################
# Unit Test
#################################################

require 'rational' if !defined?(Rational) # For Ruby 1.8

gem "minitest"
require 'minitest/autorun'

class TestUnitNilClass < MiniTest::Test
  T = true
  F = false
  InfF = Float::INFINITY
  InfP = RangeExtd::Infinity::POSITIVE
  InfN = RangeExtd::Infinity::NEGATIVE

  class CLC2
    include Comparable
  end

  # Used in test_range_c3c4 and test_rangeextd_new_infinity_c3
  class CLC3
    include Comparable
    # alias :original_compare :<=> if !self.method_defined?(:original_compare)	# No overwriting.
    def <=>(c)
      if c == 7
        "XXX"	# Bad statement.  Just for the sake of test.
      elsif c == 8
        -1
      elsif c.class == CLC4
        -1	# basically, CLC3 < CLC4
      else       # When self does not know what to do with c.
        super    # to call Object#<=>
        #original_compare(c)  # to call the original
      end
    end
  end

  # Used in test_range_c3c4
  class CLC4
    include Comparable
    def <=>(c)
      if c.class == CLC3
        1	# basically, CLC3 < CLC4
      else
        super
      end
    end
  end

  def setup
  end

  def teardown
  end

  def test_nil_class
    nowhere = RangeExtd::Nowhere::NOWHERE
    refute(nil.eql?(nowhere))
    assert( nil == nowhere )
    assert_equal 0, ( nil <=> nowhere )

    refute nil.nowhere?
    assert_equal NilClass, nil.class_raw
    assert_equal NilClass, nil.class
  end  # def test_nil_class

  # When "range_extd/numeric" is required,
  # InfP (RangeExtd::Infinity::POSITIVE) and InfN (RangeExtd::Infinity::NEGATIVE)
  # are always comparable with any comparable objects except for
  # Float::INFINITY, in which case ArgumentError is raised.
  def test_infinity_compare
    assert_operator            7.7, '<', InfF
    assert_operator            7.7, '<', InfP
    assert_operator            7.7, '>', InfN
    assert_operator           InfP, '>', 7.7
    assert_operator           InfN, '<', 7.7
    assert_operator              8, '<', InfF
    assert_operator              8, '<', InfP
    assert_operator Rational(2, 3), '<', InfF
    assert_operator Rational(2, 3), '<', InfP
    assert_operator           InfP, '>', Rational(2, 3)
    assert_operator           InfN, '<', Rational(2, 3)
    assert_operator 'h', '<',  InfP
    assert_operator 'h', '>',  InfN
    assert_raises(ArgumentError) { InfF <  InfP }
    assert_raises(ArgumentError) { InfP <  InfF }
    assert_raises(ArgumentError) { InfP < -InfF }
    assert_raises(ArgumentError) { InfP >  InfF }
    assert_raises(ArgumentError) { InfP > -InfF }
    assert_raises(ArgumentError) { InfN <  InfF }
    assert_raises(ArgumentError) { InfN < -InfF }
    assert_raises(ArgumentError) { InfF < Object.new }
    assert_raises(ArgumentError) { InfP < Object.new }
    assert_nil     (InfF <=> InfP)
    assert_nil     (InfP <=> InfF)
    assert_equal(-1,  7.7 <=> InfP)
    assert_equal( 1,  7.7 <=> InfN)
    assert_equal( 1, InfP <=> 7.7)
    assert_equal(-1, InfN <=> 7.7)
    assert_equal(-1,    5 <=> InfP)
    assert_equal( 1,    5 <=> InfN)
    assert_equal( 1, InfP <=> 5)
    assert_equal(-1, InfN <=> 5)
    assert_equal(-1,  'h' <=> InfP)
    assert_equal(-1, InfN <=> 'h')
    #assert_raises(ArgumentError) { puts "##########  #{(InfP > InfF).inspect}";InfP < InfF }
    #puts "##########  #{(InfP <=> InfF).inspect}"
  end

  # Tests of examples in the document.
  def test_in_document
    # class Infinity
    assert_equal( -1, (?z <=> RangeExtd::Infinity::POSITIVE))
    assert_equal   1, (RangeExtd::Infinity::POSITIVE <=> ?z)
    assert_equal( -1, (50 <=> RangeExtd::Infinity::POSITIVE))
    assert_equal   1, (RangeExtd::Infinity::POSITIVE <=> 50)
  end

  def test_rangeextd_new_infinity_c2
    c2 = CLC2.new
    assert_nil  (c2 <=> 1)	# Object#<=>
    assert_equal(-1, (c2 <=> RangeExtd::Infinity::POSITIVE))
    assert_equal  1, (c2 <=> RangeExtd::Infinity::NEGATIVE)
    r=(c2..RangeExtd::Infinity::POSITIVE)
    assert_equal RangeExtd::Infinity::POSITIVE, r.end
    r=(RangeExtd::Infinity::NEGATIVE..c2)
    assert_equal RangeExtd::Infinity::NEGATIVE, r.begin

    assert_raises(ArgumentError){ (true..RangeExtd::Infinity::POSITIVE) }	# => bad value for range
  end	# def test_rangeextd_new_infinity_c2

  def test_rangeextd_new_infinity_c3
    c3 = CLC3.new
    assert_equal(-1, (c3 <=> RangeExtd::Infinity::POSITIVE))
    assert_equal  1, (c3 <=> RangeExtd::Infinity::NEGATIVE)

    r=(c3..RangeExtd::Infinity::POSITIVE)
    assert_equal RangeExtd::Infinity::POSITIVE, r.end
    r=(RangeExtd::Infinity::NEGATIVE..c3)
    assert_equal RangeExtd::Infinity::NEGATIVE, r.begin
  end	# def test_rangeextd_new_infinity_c3

end # class TestUnitNilClass < MiniTest::Test

