# -*- encoding: utf-8 -*-

$stdout.sync=true
$stderr.sync=true

# print '$LOAD_PATH=';p $LOAD_PATH
arlibbase = %w(range_extd range_extd/infinity)	# range_extd/infinity is actually loaded from range_extd.  But by writing here, the absolute path will be displayed.

arlibrelbase = arlibbase.map{|i| "../lib/"+i}

arlibrelbase.each do |elibbase|
  require_relative elibbase
end	# arlibbase.each do |elibbase|

print "NOTE: Running: "; p File.basename(__FILE__)
print "NOTE: Library relative paths: "; p arlibrelbase
arlibbase4full = arlibbase.map{|i| i.sub(%r@^(../)+@, "")}+%w(range_extd)
puts  "NOTE: Library full paths for #{arlibbase4full.inspect}: "
arlibbase4full.each do |elibbase|
  ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(File.basename(elibbase))}(\.rb)?$/).uniq
  print elibbase+": " if ar.empty?; p ar
end


#################################################
# Unit Test
#################################################

begin
  _ = Rational(2, 3)
rescue
  require 'rational'
end

#if $0 == __FILE__
gem "minitest"
# require 'minitest/unit'
  require 'minitest/autorun'
  # MiniTest::Unit.autorun

  # Taken from ((<URL:http://www.ruby-doc.org/core-2.1.1/Range.html>))
  class Xs                # represent a string of 'x's
    include Comparable
    attr :length
    def initialize(n)
      @length = n
    end
    def succ
      Xs.new(@length + 1)
    end
    def <=>(other)
      # Apparently, this affects :== as well!!
      # Therefore, (Xs.new(4) == Object.new) would raise NoMethodError, whereas (Object.new == Xs.new(4)) just returns false.
      @length <=> other.length
    end
    def to_s
      sprintf "%2d #{inspect}", @length
    end
    def inspect
      'x' * @length
    end
  end

  # Used in test_overwrite_compare
  class CLComparable
    include Comparable
    def <=>(c)
      # Badly designed, deliberately.
      if c == 7
        "XXX"
      elsif c == 8
        __method__	# => :<=>
      else
        nil
        # super		# BTW, this is the statement that should be.
      end
    end
  end

  # Used in test_rangeextd_new_infinity
  # The absolute minimum Comparable class.
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

  # Used in test_bsearch_special
  class Special
    def [](f)
      (f>3.5 && f<4) ? true : false
    end
  end

  def RaE(*rest)
    RangeExtd(*rest)
  end

  class TestUnitFoo < MiniTest::Test
    T = true
    F = false
    InfF = Float::INFINITY
    InfP = RangeExtd::Infinity::POSITIVE
    InfN = RangeExtd::Infinity::NEGATIVE
    NOWHERE = RangeExtd::Nowhere::NOWHERE

    def setup
      @ib = 1
      @ie = 6
      @r11 = (@ib..@ie)		# incl, incl
      @r12 = (@ib...@ie)	# incl, excl
      @s11 = RangeExtd.new(@r11,  false)	# (1..6)   incl, incl
      @s21 = RangeExtd.new(@r11,  true)	# (1<..6)  excl, incl
      @s12 = RangeExtd.new(@r12,  false)	# (1...6)  incl, excl
      @s22 = RangeExtd.new(@r12,  true)	# (1<...6) excl, excl
    end
    # teardown is not often used.
    def teardown
      @foo = nil
    end

    ####################################
    # Ruby behaviours (to check out)
    ####################################

    def test_object_compare
      assert_equal 0, (3 <=> 3)
      assert_equal 1, (4 <=> 3)
      assert_equal 1, (?b <=> ?a)
      assert_equal 0, (nil <=> nil)
      assert_equal 0, (true <=> true)
      assert_equal 0, (IO <=> IO)
    end	# def test_object_compare

    # Ruby-2.7 (and 3.1) default behaviours.
    def test_ruby27_range01
      num1 = (5..InfF)
      num2 = (5..)
      assert( num1.end != num2.end )
      assert_equal InfF, num1.size
      assert_equal InfF, num2.size

      str1 = (?a..)
      assert( str1.end != num1.end )
      assert( str1.end == num2.end )
      assert_nil str1.size, "For some reason, this is nil in Ruby 3.1"
      assert_equal InfF, (..?z).size
    end	# def test_ruby27_range

    # Ruby-2.7 (and 3.1) default behaviours.
    def test_ruby27_range_nil
      assert_equal "..3", (..3).to_s
      assert_equal "3..", (3..).to_s
      assert_equal "3..", (3..nil).to_s
      assert_equal "..3", (nil..3).to_s

      assert( (nil..) == (..nil) )  # 
      assert( (nil..) != (...nil))  # (because (I guess) exclude_end? differ)
      assert( (...nil).exclude_end? )  # (because (I guess) exclude_end? differ)
      assert_equal "abcdef", "abcdef"[..nil] # (i.e., it is interpreted as (0..IntegerInfinity)
                           #    (n.b., nil.to_i==0; Integer(nil) #=> TypeError))
      assert_raises(TypeError){ "abcdef"[..?a] } # raise: no implicit conversion of String into Integer (TypeError)
      assert_equal "abcdef", "abcdef"[0..100]
      assert_nil   "abcdef"[-100..100]

      assert_equal InfF, (..nil).size

      assert_nil (..nil).begin
      assert_raises(RangeError){ (..nil).first} # raise: cannot get the first element of beginless range (RangeError)
      assert_raises(RangeError){ (..nil).last } # raise: cannot get the last element of endless range (RangeError)
      assert_nil (..nil).end

      assert( (..nil).cover? 5   )
      assert( (..nil).cover? ?a  )
      assert( (..nil).cover? [?a])
      assert( (..nil).cover? nil )
    end	# def test_ruby27_range_nil

    # Ruby-2.7 (and 3.1) default behaviours.
    def test_ruby27_range_int
      num1 = (5..Float::INFINITY)
      num2 = (5..)
      assert( num1.end != num2.end)  # (because I guess (Float::INFINITY != nil))
      assert_equal InfF, num1.size
      assert_equal InfF, num2.size

      assert (3...) == (3...nil)
      assert (3..)  != (3...nil) #  (because I guess exclude_end? differ)

      assert_equal InfF, (3..).size
      assert_nil   (..3).begin  # => nil
      assert_raises(RangeError){ (..3).first} # raise: cannot get the first element of beginless range (RangeError)
      assert_raises(RangeError){ (3..).last } # raise: cannot get the last element of endless range (RangeError)
      assert_nil   (3..).end    # => nil
      assert_raises(TypeError){ (..3).each{}} # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(TypeError){ (..3).to_a  } # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(RangeError){ (3..).to_a } # raise: `to_a': cannot convert endless range to an array (RangeError)
      # (3..Float::INFINITY).to_a    # => Infinite loop!

      assert_equal(-InfF, (-Float::INFINITY..4).first)
      assert_equal  InfF, (4..Float::INFINITY).last
      assert_raises(TypeError){ (-Float::INFINITY..4).first(2)} # raise: can't iterate from Float (TypeError)
      # (4..Float::INFINITY).last(2) # Infinite loop!
    end # def test_ruby27_range_int

    # Ruby-2.7 (and 3.1) default behaviours.
    def test_ruby27_range_string
      assert((?a..).end   == (5..).end)   # (because both are nil)
      assert((?a..).end   != (5..Float::INFINITY).end)
      assert((..?a).begin == (..5).begin) # (because both are nil)
      assert((..?a).begin != ((-Float::INFINITY)..5).begin)
      assert_nil (?a..?b).size  # Range#size is nil except for Numeric Ranges (specification).
      assert_equal InfF, (..?a).size  # Therefore, this contradicts the specification.
      assert_nil (?a..).size

      assert_nil (..?a).begin
      assert_raises(RangeError){ (..?a).first} # raise: cannot get the first element of beginless range (RangeError)
      assert_raises(RangeError){ (?a..).last } # raise: cannot get the last element of endless range (RangeError)
      assert_nil (?a..).end
      assert_raises(TypeError){ (..?a).each{}} # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(TypeError){ (..?a).to_a  } # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(RangeError){(?a..).to_a  } # raise: `to_a': cannot convert endless range to an array (RangeError)
      assert_raises(ArgumentError){ (?a..Float::INFINITY).to_a } # raise: bad value for range (ArgumentError)  # b/c it is not String!
    end # def test_ruby27_range_string

    ####################################
    # RangeExtd behaviours
    ####################################

    # Tests listed in the doc
    def test_doc_first
      assert_equal Float::INFINITY, RaE(..nil).size
      assert_nil   RaE(..nil).begin
      assert_raises(RangeError){RaE(..nil).first} # raise: cannot get the first element of beginless range (RangeError)
      assert_raises(RangeError){RaE(..nil).last}  # raise: cannot get the last element of endless range (RangeError)
      assert_nil RaE(..nil).end
      assert     RaE(..nil).cover? 5
      assert     RaE(..nil).cover? ?a
      assert     RaE(..nil).cover? [?a]
      assert     RaE(..nil).cover? nil
    end

    # Tests listed in the doc
    def test_doc_integer
      assert_equal((3...), RaE(3...nil))
      refute_equal((3..),  RaE(3...nil))  #  (because exclude_end? differ))
      assert_equal(RaE(3...nil), (3...))
      refute_equal(RaE(3...nil), (3..) )  #  (because exclude_end? differ))
      assert_equal Float::INFINITY, RaE(3..).size
      assert_nil  RaE(..3).begin
      assert_raises(RangeError, "first() should raise RangeError"){RaE(..3).first} # raise: cannot get the first element of beginless range (RangeError)
      assert_raises(RangeError, "last() should raise RangeError"){RaE(3..).last}  # raise: cannot get the last element of endless range (RangeError)
      assert_nil  RaE(3..).end
      assert_raises(TypeError){RaE(..3).each{}} # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(TypeError){RaE(..3).to_a}   # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(RangeError){RaE(3..).to_a}  # raise: `to_a': cannot convert endless range to an array (RangeError)
      #  (3..Float::INFINITY).to_a  # Infinite loop!
    end

    # Tests listed in the doc
    def test_doc_string
      assert(    (5..).end == RaE(?a..).end)  # for direct comparison, assert_nil is required!
      assert( RaE(5..).end ==    (?a..).end)
      assert( RaE(5..).end == RaE(?a..).end)
      refute_equal(   (5..Float::INFINITY).end, RaE(?a..).end)
      refute_equal(RaE(5..Float::INFINITY).end,    (?a..).end)
      refute_equal(RaE(5..Float::INFINITY).end, RaE(?a..).end)
      assert(    (..5).begin == RaE(..?a).begin)  # (because both are nil)
      assert( RaE(..5).begin ==    (..?a).begin)
      assert( RaE(..5).begin == RaE(..?a).begin)
      refute_equal(   ((-Float::INFINITY)..5).begin, RaE(..?a).begin)
      refute_equal(RaE((-Float::INFINITY)..5).begin,    (..?a).begin)
      refute_equal(RaE((-Float::INFINITY)..5).begin, RaE(..?a).begin)
      assert_equal Float::INFINITY, RaE(..?a).size
      assert_nil RaE(?a..).size

      assert_nil RaE(..?a).begin
      assert_raises(RangeError){RaE(..?a).first} # raise: cannot get the first element of beginless range (RangeError)
      assert_raises(RangeError){RaE(?a..).last}  # raise: cannot get the last element of endless range (RangeError)
      assert_nil RaE(?a..).end
      assert_raises(TypeError){RaE(..?a).each{}} # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(TypeError){RaE(..?a).to_a}   # raise: `each': can't iterate from NilClass (TypeError)
      assert_raises(RangeError){RaE(?a..).to_a}  # raise: `to_a': cannot convert endless range to an array (RangeError)
      assert_raises(ArgumentError){RaE(?a..Float::INFINITY).to_a}  # raise: bad value for range (ArgumentError)  # b/c it is not String!
    end

    # IF and only if "range_extd/numeric" is required,
    # InfP (RangeExtd::Infinity::POSITIVE) and InfN (RangeExtd::Infinity::NEGATIVE)
    # are always comparable with any comparable objects except for
    # Float::INFINITY, in which case ArgumentError is raised.
    #
    # In this case, the file is not required.
    def test_infinity_compare
      assert_operator            7.7, '<', InfF
      assert_raises(ArgumentError){ 7.7 < InfP }
      assert_raises(ArgumentError){ 7.7 > InfN }
      assert_operator           InfP, '>', 7.7
      assert_operator           InfN, '<', 7.7
      assert_operator              8, '<', InfF
      assert_raises(ArgumentError){ 8 < InfP }
      assert_operator Rational(2, 3), '<', InfF
      assert_raises(ArgumentError){ Rational(2, 3) < InfP }
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
      assert_nil( 7.7 <=> InfP)
      assert_nil( 7.7 <=> InfN)
      assert_equal( 1, InfP <=> 7.7)
      assert_equal(-1, InfN <=> 7.7)
      assert_nil( 5 <=> InfP)
      assert_nil( 5 <=> InfN)
      assert_equal( 1, InfP <=> 5)
      assert_equal(-1, InfN <=> 5)
      assert_equal(-1,  'h' <=> InfP)
      assert_equal(-1, InfN <=> 'h')
      #assert_raises(ArgumentError) { puts "##########  #{(InfP > InfF).inspect}";InfP < InfF }
      #puts "##########  #{(InfP <=> InfF).inspect}"
    end

    def test_overwrite_compare
      assert_nil     (Float::INFINITY <=> RangeExtd::Infinity::POSITIVE)
      assert_nil  RangeExtd::Infinity.overwrite_compare(Numeric)
      assert_nil     (Float::INFINITY <=> RangeExtd::Infinity::POSITIVE)	# no change
      assert_nil  RangeExtd::Infinity.overwrite_compare(3)
      assert_nil     (Float::INFINITY <=> RangeExtd::Infinity::POSITIVE)	# no change
      assert_equal false, RangeExtd::Infinity.overwrite_compare(true)	# no change
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> 's')
      assert_equal(-1, ('s' <=> RangeExtd::Infinity::POSITIVE))
      assert_equal(-1, (RangeExtd::Infinity::NEGATIVE <=> 's'))
      assert_equal  1, ('s' <=> RangeExtd::Infinity::NEGATIVE)
      assert_nil  RangeExtd::Infinity.overwrite_compare('s')	# no change
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> 's')
      assert_equal(-1, ('s' <=> RangeExtd::Infinity::POSITIVE))
      assert_equal(-1, (RangeExtd::Infinity::NEGATIVE <=> 's'))
      assert_equal  1, ('s' <=> RangeExtd::Infinity::NEGATIVE)
      assert_nil  RangeExtd::Infinity::POSITIVE <=> [3,5]
      assert_nil  ([3,5] <=> RangeExtd::Infinity::POSITIVE)	# no change
      assert_nil  (defined? [3,5].compare_before_infinity)
      assert_equal false, RangeExtd::Infinity.overwrite_compare([3,5])

      # This used to give false; Hash#<= used to be undefined in old-version Ruby.
      # But as of Ruby-2.6, it is defined!
      assert_equal Hash.method_defined?(:<=), RangeExtd::Infinity.overwrite_compare(Hash)	# no change

      c = CLComparable.new
      assert_equal 'XXX', (c <=> 7)	# Defined in this code
      assert_nil  (c <=> 1)	# Object#<=>
      assert_nil  (c <=> RangeExtd::Infinity::POSITIVE)
      assert_raises(ArgumentError){ (c..RangeExtd::Infinity::POSITIVE) }	# => bad value for range
      assert_equal true, RangeExtd::Infinity.overwrite_compare(c)
      assert_equal(-1, (c <=> RangeExtd::Infinity::POSITIVE))
      assert_equal  1, (c <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal 'method', (defined? c.compare_before_infinity)	# Backup of the original
      assert_equal 'XXX', (c.compare_before_infinity(7))	# Preserved.
      assert_equal 'XXX', (c <=> 7)	# Preserved.
      assert_nil  (c <=> 1)
      assert_nil  (c <=> nil)
      assert_equal :<=>,  (c <=> 8)
    end

    def test_rangeextd_new_infinity_c2
      c2 = CLC2.new
      assert_nil  (c2 <=> 1)	# Object#<=>
      assert_nil(c2 <=> RangeExtd::Infinity::POSITIVE)
      assert_nil(c2 <=> RangeExtd::Infinity::NEGATIVE)
      assert_raises(ArgumentError, '"bad value for range" should be raised when object.rb is not required'){ (c2..RangeExtd::Infinity::POSITIVE) }
      r=(RangeExtd::Infinity::NEGATIVE..c2)  # This is OK at least in Ruby-3.1 because (RangeExtd::Infinity::NEGATIVE <=> c2) is valid.
      assert_equal RangeExtd::Infinity::NEGATIVE, r.begin

      assert_raises(ArgumentError){ (true..RangeExtd::Infinity::POSITIVE) }	# => bad value for range
    end	# def test_rangeextd_new_infinity_c2

    def test_range_c3c4
      c3 = CLC3.new
      assert_nil          (c3 <=> 1)	# Object#<=>
      assert_equal 'XXX', (c3 <=> 7)	# Preserved.

      r8=(c3..8)
      assert_equal 8, r8.end
      assert !r8.valid?		# Because (c3<=>8) is not commutative: (c3<=>8) != (8<=>c3)
      assert_raises(ArgumentError){ (8..c3) }	# => bad value for range  (8<=>c3  # => nil)

      c4 = CLC4.new
      r34=(c3..c4)	# c3 and c4 are consistently commutative: c3 < c4
      r43=(c4..c3)
      assert_equal c3, r34.begin
      assert_equal c4, r34.end
      assert  r34.valid?
      assert !r43.valid?	# Because c3 < c4
    end	# def test_range_c3c4

    def test_rangeextd_new_infinity_c3
      c3 = CLC3.new
      assert_nil(c3 <=> RangeExtd::Infinity::POSITIVE)
      assert_nil(c3 <=> RangeExtd::Infinity::NEGATIVE)

      assert_raises(ArgumentError, '"bad value for range" should be raised when object.rb is not required'){(c3..RangeExtd::Infinity::POSITIVE) }
      r=(RangeExtd::Infinity::NEGATIVE..c3)  # This is OK at least in Ruby-3.1 because (RangeExtd::Infinity::NEGATIVE <=> c3) is valid.
      assert_equal RangeExtd::Infinity::NEGATIVE, r.begin
    end	# def test_rangeextd_new_infinity_c3

    def test_get_init_args
      begin
        _ = (0..nil)
      rescue ArgumentError
        return  # Before Ruby 2.6
      end
      arout = RangeExtd.class_eval{ _get_init_args(3, nil) }	# class_eval from Ruby 1.8.7 (?)
      assert_equal [3, nil, F, F], arout
      arout = RangeExtd.class_eval{ _get_init_args(3, nil, F, T) }  # true == exclude_end?
      assert_equal [3, nil, F, T], arout
    end

    def test_new
      e22 = RangeExtd.new(@s22)
      assert  e22.exclude_begin?
      assert  e22.exclude_end?
      assert_equal @ib, e22.begin
      assert_equal @ie, e22.end

      f12 = RangeExtd.new(@r12)
      assert !f12.exclude_begin?
      assert  f12.exclude_end?
      assert_equal @ib, f12.begin
      assert_equal @ie, f12.end

      g11 = RangeExtd.new(@ib, @ie)
      assert !g11.exclude_begin?
      assert !g11.exclude_end?
      assert_equal @ib, g11.begin
      assert_equal @ie, g11.end

      h12 = RangeExtd.new(@ib, @ie, true)
      assert  h12.exclude_begin?
      assert !h12.exclude_end?
      assert_equal @ib, h12.begin
      assert_equal @ie, h12.end

      j22 = RangeExtd.new(-@ie, -@ib, true, true)
      assert  j22.exclude_begin?
      assert  j22.exclude_end?
      assert_equal(-@ie, j22.begin)
      assert_equal(-@ib, j22.end)
    end

    def test_new_endless_range01
      begin
        _ = (0..nil)
      rescue ArgumentError
        # Before Ruby 2.6
        assert_raises(ArgumentError) {RangeExtd.new(-2, nil)}
        return  # Before Ruby 2.6
      end

      # Ruby 2.6 upwards
      ra00 = (-2..)  # This raises the uncapturable SyntaxError for Ruby 2.5 and before anyway.
      rae0 = RangeExtd.new(ra00)
      assert rae0.valid?
      assert_equal(-2,  rae0.begin)
      assert_nil        rae0.end
      assert_equal Float::INFINITY,   rae0.size
      assert_equal ra00.exclude_end?, rae0.exclude_end?
      refute                          rae0.exclude_begin?

      rae0 = RangeExtd.new(-2, nil)
      assert rae0.valid?
      assert_equal(-2,  rae0.begin)
      assert_nil        rae0.end
      assert_equal Float::INFINITY,   rae0.size
      assert_equal ra00.exclude_end?, rae0.exclude_end?
      refute                          rae0.exclude_begin?
    end

    def test_new_endless_range02
      begin
        _ = (?d...nil)
      rescue ArgumentError
        # Before Ruby 2.6
        assert_raises(ArgumentError) {RangeExtd.new(?d, nil)}
        return  # Before Ruby 2.6
      end

      # Ruby 2.6 upwards
      ra00 = (Float::INFINITY...)  # This raises the uncapturable SyntaxError for Ruby 2.5 and before anyway.
      rae0 = RangeExtd.new(ra00)
      assert rae0.valid?
      assert_equal Float::INFINITY,   rae0.begin
      assert_nil        rae0.end
      assert_equal Float::INFINITY,   rae0.size
      assert_equal ra00.exclude_end?, rae0.exclude_end?
      refute                          rae0.exclude_begin?

      # https://ruby-doc.org/core-3.1.2/Range.html#method-i-size],
      # > Returns the count of elements in self if both begin and end values are numeric; otherwise, returns nil
      assert( (?d..).size == RangeExtd.new(?d, RangeExtd::Infinity::POSITIVE).size )
      assert( (..?d).size == RangeExtd.new(RangeExtd::Infinity::NEGATIVE, ?d).size )

      rae0 = RangeExtd.new(?d, nil, false, true)
      assert rae0.valid?
      assert_equal(?d,  rae0.begin)
      assert_nil        rae0.end
      # assert_equal (?d..nil).size, rae0.size   # assert_nil warning!
      assert_nil  (?d..nil).size
      assert_nil  rae0.size
      assert_equal true,           rae0.exclude_end?
      refute                       rae0.exclude_begin?
    end

    def test_new_endless_range03
      begin
        _ = (?d...nil)
      rescue ArgumentError
        # Before Ruby 2.6
        assert_raises(ArgumentError) {RangeExtd.new(?d, nil)}
        return  # Before Ruby 2.6
      end

      ra00 = (-Float::INFINITY...)  # This raises the uncapturable SyntaxError for Ruby 2.5 and before anyway.
      rae0 = RangeExtd.new(ra00)
      assert rae0.valid?
      assert_equal(-Float::INFINITY,   rae0.begin)
      assert_nil         rae0.end
      assert_equal  Float::INFINITY,   rae0.size
      assert_equal  ra00.exclude_end?, rae0.exclude_end?
      refute                           rae0.exclude_begin?
    end

    def test_new_endless_range04
      # Ruby 2.7 and later
      #
      # Note this would raise a SytaxError for the versions before 2.7.

      assert_equal  9, RangeExtd(..9).end
      assert_equal ?d, RangeExtd(..?d).end
      assert_equal ?d, RangeExtd(..?d).last
      assert_equal ?d, RangeExtd(..?d, true).last
      assert_nil       RangeExtd(..9).begin
      assert_raises(RangeError){ RangeExtd(..9).first} # raise: cannot get the first element of beginless range (RangeError)
      assert_nil       RangeExtd(..?d).begin
      assert_raises(RangeError){ (..?d).first} # raise: cannot get the first element of beginless range (RangeError)

      # (nil..nil).size is Infininty, even thouth it does not agree with Ruby's doc's specification.
      assert_equal (nil..).size, RaE(InfN...InfP, true).size
      assert_equal (nil..).size,    (InfN..InfP).size
      assert_equal (nil..).size,    (InfN...InfP).size
      assert_equal (-InfF..InfF).size, RaE(-InfF..InfF, true).size
      assert_equal    0,    (InfP..InfN).size
      assert_raises(FloatDomainError){ (InfP..InfP).size} # NaN
      assert_raises(FloatDomainError){ (InfN..InfN).size} # NaN
      assert( (nil..?a).size == (InfN..?a).size )
      assert( (?a..nil).size == (?a..InfP).size )
    end

    def test_new_middle_strings
      aru = ['[','(in)','(ex)',', ','(ex)','(in)',']']
      ark = [nil, :math, aru, :default]

      ars = ['..', '<=x<=', aru[1]+aru[3]+aru[5]]; ars.push(ars[0])
      ark.each_index do |i|
        RangeExtd.middle_strings = ark[i] if ! ark[i].nil?
        k11 = RangeExtd.new(@ib, ars[i], @ie)
        assert !k11.exclude_begin?
        assert !k11.exclude_end?
        assert_equal @ib, k11.begin
        assert_equal @ie, k11.end
      end

      ars = ['...', '<=x<', aru[1]+aru[3]+aru[4]]; ars.push(ars[0])
      ark.each_index do |i|
        RangeExtd.middle_strings = ark[i] if ! ark[i].nil?
        k12 = RangeExtd.new(@ib, ars[i], @ie)
        assert !k12.exclude_begin?
        assert  k12.exclude_end?
        assert_equal @ib, k12.begin
        assert_equal @ie, k12.end
      end

      ars = ['<..', '<x<=', aru[2]+aru[3]+aru[5]]; ars.push(ars[0])
      ark.each_index do |i|
        RangeExtd.middle_strings = ark[i] if ! ark[i].nil?
        k21 = RangeExtd.new(@ib, ars[i], @ie)
        assert  k21.exclude_begin?
        assert !k21.exclude_end?
        assert_equal @ib, k21.begin
        assert_equal @ie, k21.end
      end

      ars = ['<...', '<x<', aru[2]+aru[3]+aru[4]]; ars.push(ars[0])
      ark.each_index do |i|
        RangeExtd.middle_strings = ark[i] if ! ark[i].nil?
        k22 = RangeExtd.new(@ib, ars[i], @ie)
        assert  k22.exclude_begin?
        assert  k22.exclude_end?
        assert_equal @ib, k22.begin
        assert_equal @ie, k22.end
      end

      l12 = RangeExtd.new(@ib, '..', @ie, true)
      assert  l12.exclude_begin?
      assert !l12.exclude_end?
      assert_equal @ib, l12.begin
      assert_equal @ie, l12.end

      m22 = RangeExtd.new(-@ie, '..', -@ib, true, true)
      assert  m22.exclude_begin?
      assert  m22.exclude_end?
      assert_equal(-@ie, m22.begin)
      assert_equal(-@ib, m22.end)

      assert_raises(RangeError){ RangeExtd.new(@ib, '....', @ie) }	# => the combination of the arguments does not constitute a valid RangeExtd instance.
        # Basically, for @ib, @ie == [1, 6],
        # the user may intend to write "1....6", but it is interpreted as
        #   ((1..("....")), exclude_begin: (!!6))
        # hence it is RangeError (as opposed to ArgumentError)

      rt0 = RangeExtd.new("%", '....', "y")
      assert_equal "%",    rt0.begin
      assert_equal '....', rt0.end
      assert               rt0.exclude_begin?
      refute               rt0.exclude_end?

      RangeExtd.middle_strings = :math
      assert_raises(RangeError){ RangeExtd.new(@ib, '..', @ie) }	# => the combination of the arguments does not constitute a valid RangeExtd instance.

      RangeExtd.middle_strings = :default
      assert_raises(ArgumentError){ RangeExtd.new(@ib, '..', @ie, T, nil, T) }	# => wrong number of arguments (6 for 1..5)
      assert_raises(ArgumentError){ RangeExtd.new(@ib, @ie, T, nil, T) }	# => wrong number of arguments (5 for 2..4)
      assert_raises(ArgumentError){ RangeExtd.new(@ib) }	# => wrong number of arguments (1 for 2..5)
    end	# def test_new_middle_strings

    def test_new_const
      assert_equal @s22, RangeExtd(@r12, true)
    end

    def test_new_invalid
      ae = ArgumentError
      re = RangeError
      # Wrong number of parameters
      assert_raises(ae){ RangeExtd() }
      assert_raises(ae){ RangeExtd(1,2,3,4,5) }
      assert_raises(ae){ RangeExtd(1,2,3,4,{},6) }
      assert_raises(ae){ RangeExtd(1..1,2,3,4) }
      assert_raises(ae){ RangeExtd(1..1,2,3,{},5) }

      # Wrong range (Object input)
      assert_raises(re){ RaE(2, -1) }
      assert( RaE(nil, nil).valid?, 'RangeExtd(nil,nil) should be valid now, but..' )
      assert( RaE(nil..nil).valid?, 'RangeExtd(nil..nil) should be valid now, but..' )
      assert_raises(re){ RaE(nil, false) }
      assert_raises(re){ RaE(?d..?a) }
      assert_raises(re){ RaE(?a, 5) }
      assert_raises(re){ RaE(0, 0, true, false) }
      assert_raises(re){ RaE(0, 0, nil,  1) }
      assert_equal RangeExtd::NONE, RaE(0, 0, true, true)
      assert_equal RangeExtd::NONE, RaE(?a, ?a, true, true)
      assert_equal (0..0), RaE(0, 0, false, false)

      # The following used to raise RangeError (Ver.0.4 and 1.0) or ArgumentError (<= Ver.0.4.0)
      assert_output('', /Infinity/i){RaE(RangeExtd::Infinity::NEGATIVE,  Float::INFINITY)}  # Warning = "RangeExtd component of the RangeExtd::Infinity object replaced with Float::INFINITY"
      capture_io{
        ra_b = RaE(InfN, InfF).begin  # RangeExtd::Infinity::NEGATIVE replaced with -Float::INFINITY
        assert_equal(   -InfF, ra_b)
        assert_operator Float, '===', ra_b
      }

      # Wrong range (Infinity input)
      assert_raises(re){ RaE(?a, RangeExtd::Infinity::NEGATIVE) }
      assert_equal (RangeExtd::Infinity::NEGATIVE..?a),  RaE(RangeExtd::Infinity::NEGATIVE, ?a)
      assert_equal (RangeExtd::Infinity::NEGATIVE...?a), RaE(RangeExtd::Infinity::NEGATIVE, ?a, nil, 3)
      assert_equal (?a..RangeExtd::Infinity::POSITIVE),  RaE(?a, RangeExtd::Infinity::POSITIVE)
      assert_equal RangeExtd, RaE(?a, RangeExtd::Infinity::POSITIVE, 1).class

      assert_raises(re){ RaE(RangeExtd::Infinity::POSITIVE, ?a) }
      assert_raises(re){      RaE(RangeExtd::Infinity::POSITIVE, RangeExtd::Infinity::NEGATIVE) }
      assert_equal RangeExtd, RaE(RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::POSITIVE).class
      # assert_raises(re){ RaE(RangeExtd::Infinity::NEGATIVE, 0, false, false) }	# For Numeric, you should use -Float::INFINITY
      # assert_raises(re){ RaE(0, RangeExtd::Infinity::POSITIVE, false, false) }	# For Numeric, you should use  Float::INFINITY
      assert_equal RangeExtd, RaE(RangeExtd::Infinity::NEGATIVE, ?a, false, false).class
      assert_equal RangeExtd, RaE(?a, RangeExtd::Infinity::POSITIVE, false, false).class
      # assert_raises(ae){ RaE(RangeExtd::Infinity::NEGATIVE, ?a, true) }	#### No exception.  Is it OK???
      # assert_raises(ae){ RaE(?a, RangeExtd::Infinity::POSITIVE, nil, 1) }	#### No exception.  Is it OK???

      # Wrong range (Range input)
      assert_raises(re){ RangeExtd(2..-1) }
      assert_raises(re){ RangeExtd(?d..?a) }

      # Range with contradictory boundary
      assert_equal ?a..?e,  RaE(?a...?e, nil, nil)
      assert_equal ?a...?e, RaE(?a..?e,  nil,   1)
      assert_equal ?a..?a,  RaE(?a...?a, nil, nil)
      assert_equal RangeExtd::NONE, RaE(?a...?a, 1, 1)
      assert_equal RangeExtd::NONE, RaE(?a..?b,  1, 1)
      assert_raises(re){ RaE(?a..?a, true, nil) }
      assert_raises(re){ RaE(?a..?a,  nil,   1) }
    end

    def test_new_invalid_endless_range01
      ra01 = (true..)
      refute RangeExtd.valid?(ra01)
      assert_raises(RangeError){ RangeExtd.new(ra01)} # the combination of the arguments does not constitute a valid RangeExtd instance.
      ra02 = (..true)
      refute RangeExtd.valid?(ra02)
      assert_raises(RangeError){ RangeExtd.new(ra02)} # the combination of the arguments does not constitute a valid RangeExtd instance.
    end

    def test_new_valid_endless_range02
      ras = [(nil..nil), (nil...nil), RangeExtd((..nil), true), RangeExtd((...nil), true)] 
      # These raise the uncapturable SyntaxError for Ruby 2.5 and earlier.
      # However, the former two are a meaningful expression in Ruby-2.7+
      ras.each do |er|
        assert RangeExtd.valid?(er), er.inspect+" should be valid now."
        RangeExtd.new(er)  # Nothing should be raised
      end
    end

    def test_new_exclude_begin_end
      # Form 1: 1 parameters
      assert !RangeExtd(3..5).exclude_begin?
      assert !RangeExtd(3..5).exclude_end?
      assert !RangeExtd(3..5).exclude_begin?
      assert  RangeExtd(3...5).exclude_end?

      # Form 1: 1 parameters: RangeExtd
      assert !RangeExtd(RangeExtd(3...5)).exclude_begin?
      assert  RangeExtd(RangeExtd(3...5)).exclude_end?
      assert  RangeExtd(RangeExtd(3...5,7)).exclude_begin?

      # Form 1: 2-3 parameters
      assert  RangeExtd(3..5,7).exclude_begin?
      assert !RangeExtd(3..5,7).exclude_end?
      assert  RangeExtd(3..5,7,8).exclude_begin?
      assert  RangeExtd(3..5,7,8).exclude_end?
      assert  RangeExtd(3...5,7,8).exclude_begin?
      assert  RangeExtd(3...5,7,8).exclude_end?
      assert !RangeExtd(3...5,7,nil).exclude_end?
      assert  RangeExtd(RangeExtd(3...5,7,nil)).exclude_begin?
      assert  RangeExtd(RangeExtd(3...5,7,nil),7,8).exclude_begin?
      assert  RangeExtd(RangeExtd(3..5,7),7,8).exclude_begin?
      assert  RangeExtd(RangeExtd(3..5,7),7,8).exclude_end?
      assert !RangeExtd(RangeExtd(3...5,7),nil,nil).exclude_begin?
      assert !RangeExtd(RangeExtd(3...5,7),nil,nil).exclude_end?

      # Form 1: 2-3 parameters + opts
      assert !RangeExtd(3..5,7,     :exclude_begin =>nil).exclude_begin?
      assert  RangeExtd(3..5,7,     :exclude_end =>8).exclude_end?
      assert !RangeExtd(3..5,7,8,   :exclude_begin =>nil).exclude_begin?
      assert !RangeExtd(3..5,7,8,   :exclude_end =>nil).exclude_end?
      assert !RangeExtd(3...5,7,8,  :exclude_begin =>nil).exclude_begin?
      assert !RangeExtd(3...5,7,8,  :exclude_end =>nil).exclude_end?
      assert  RangeExtd(3...5,7,nil,:exclude_end =>9).exclude_end?

      # Form 2: 2 parameters
      assert !RangeExtd(3,5).exclude_begin?
      assert !RangeExtd(3,5).exclude_end?

      # Form 2: 3-4 parameters
      assert  RangeExtd(3,5,9).exclude_begin?
      assert !RangeExtd(3,5,9).exclude_end?
      assert  RangeExtd(3,5,true,9).exclude_begin?
      assert  RangeExtd(3,5,true,9).exclude_end?
      assert !RangeExtd(3,5,true,nil).exclude_end?

      # Form 2: 2-4 parameters + opts
      assert  RangeExtd(3,5,          :exclude_begin =>8).exclude_begin?
      assert !RangeExtd(3,5,false,    :exclude_begin =>8).exclude_end?
      assert  RangeExtd(3,5,false,    :exclude_begin =>8).exclude_begin?
      assert  RangeExtd(3,5,false,9,  :exclude_begin =>8).exclude_begin?
      assert  RangeExtd(3,5,false,9,  :exclude_begin =>8).exclude_end?
      assert !RangeExtd(3,5,false,nil,:exclude_begin =>8).exclude_end?
      assert !RangeExtd(3,5,false,9,  :exclude_begin =>nil).exclude_begin?
      assert  RangeExtd(3,5,false,9,  :exclude_begin =>false).exclude_end?
      assert  RangeExtd(3...5,false,nil,:exclude_begin =>8, :exclude_end =>8).exclude_begin?
      assert  RangeExtd(3...5,false,nil,:exclude_begin =>8, :exclude_end =>8).exclude_end?
      assert !RangeExtd(3,5,false,9,  :exclude_end =>8).exclude_begin?
      assert !RangeExtd(3,5,false,9,  :exclude_end =>false).exclude_end?
      assert  RangeExtd(3,5,false,nil,:exclude_end =>8).exclude_end?
    end

    def test_exclude_begin
      b = 1
      e = 4
      r1 = (b...e)
      assert !RangeExtd.new(r1).exclude_begin?
      assert  RangeExtd.new(r1).exclude_end?
      assert  RangeExtd.new(r1, true).exclude_begin?
      assert  RangeExtd.new(r1, true).exclude_end?
      assert !RangeExtd.new(b,e).exclude_begin?
      assert !RangeExtd.new(b,e).exclude_end?
      assert !RangeExtd.new(b,e,nil).exclude_begin?
      assert !RangeExtd.new(b,e,nil).exclude_end?
      assert  RangeExtd.new(b,e,'c').exclude_begin?
      assert !RangeExtd.new(b,e,'c').exclude_end?
      assert  RangeExtd.new(b,e, :exclude_begin => 5).exclude_begin?
      assert !RangeExtd.new(b,e, false, false).exclude_begin?
      assert !RangeExtd.new(b,e, false, false).exclude_end?
      assert !RangeExtd.new(b,e, false, true ).exclude_begin?
      assert  RangeExtd.new(b,e, false, true ).exclude_end?
      assert  RangeExtd.new(b,e, true,  true ).exclude_begin?
      assert  RangeExtd.new(b,e, true,  true ).exclude_end?
      assert  RangeExtd.new(b,e, true,  false).exclude_begin?
      assert !RangeExtd.new(b,e, true,  false).exclude_end?
      assert  RangeExtd(3,5,8,9).exclude_begin?
      assert  RangeExtd(3,5,8,9).exclude_end?

      assert_raises ArgumentError do
        RangeExtd.new()
      end
      assert_raises ArgumentError do
        RangeExtd.new(5)
      end

      RangeExtd.new(nil,5)      # used to be RangeError (in RangeExtd Ver.1), but nothing should be raised now.
      RangeExtd.new(nil,5,true) # used to be RangeError (in RangeExtd Ver.1), but nothing should be raised now.
    end	# def test_exclude_begin


    # Test of Range(Extd)#is_all? and Range#equiv_all?
    def test_is_all
      assert  (RangeExtd::ALL.is_all?)
      refute  (RangeExtd::NONE.is_all?)
      assert  (RangeExtd(RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::POSITIVE).is_all?)	# You can create it, if you want.
      assert  (RangeExtd(RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::POSITIVE).equiv_all?)
      refute  (RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE).is_all?	# Not the standard Range, though.
      assert  (RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE).equiv_all?
      refute  (-Float::INFINITY..Float::INFINITY).is_all?
      refute  (RangeExtd(-Float::INFINITY, Float::INFINITY).is_all?)	# Different from Numeric, though.
      assert  (RangeExtd(-Float::INFINITY, Float::INFINITY).equiv_all?)
      assert  (-Float::INFINITY..Float::INFINITY).equiv_all?
      assert   (nil..).equiv_all?, '(nil..) should not be *equivalent* to RangeExtd::ALL.'
      assert  ((..nil).equiv_all?)
      assert  ((nil..nil).equiv_all?)
      refute  ((nil...).equiv_all?) # because of exclude_end
      refute   (nil..).is_all?, '(nil..) should not be *identical* to RangeExtd::ALL.'
      refute  ((..nil).is_all?)
      refute  ((nil..nil).is_all?)
      refute  ((nil...).is_all?)
      assert  (nil..nil).equiv?( RangeExtd::ALL)
      refute  (nil...nil).equiv?(RangeExtd::ALL)
      assert_equal    (nil..), (..nil)
      assert_operator (nil..), :eql?, (..nil)
      assert_equal    (nil..), (RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE)
      assert_equal    (RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE), (nil..)
      assert_equal RangeExtd::ALL, (nil..)
      refute_equal RangeExtd::ALL, (nil...)
      assert_equal((nil..),  RangeExtd::ALL)
      refute_equal((nil...), RangeExtd::ALL)
      assert_equal RangeExtd::ALL, RaE((nil..))
      refute_equal RangeExtd::ALL, RaE((nil...))
      assert_equal RaE(nil..),  RangeExtd::ALL
      refute_equal RaE((nil..), true), RangeExtd::ALL
      refute_operator RangeExtd::ALL, :eql?, (nil..)  # They are NOT eql? (but :==)
      refute_operator (nil..), :eql?, RangeExtd::ALL
    end

    # Test of Range#== because it has changed first!
    def test_eql_range
      assert       (@r11 == (@ib..@ie))
      assert_equal  @r11, (@ib..@ie)
      assert       (@r11 != @r12)
      assert_equal  @r12, (@ib...@ie)
      assert_equal  @r11, @s11
      assert       (@r11 != @s12)
      assert       (@r11 != @s21)
      assert       (@r11 != @s22)
      assert_equal  @r12, @s12
      assert       (@r12 != @s11)
      assert       (@r12 != @s21)
      assert       (@r12 != @s22)
      assert       (@r12 != 'K')
      assert       (@r12 != @ib)
    end	# def test_eql_range

    def test_eql
      t21 = RangeExtd.new(@ib..@ie,true)
      u11 = RangeExtd.new(3, @ie,  false)
      v11 = RangeExtd.new(@ib, 4,  false)
      v21 = RangeExtd.new(@ib..4,  true)
      v22 = RangeExtd.new(@ib...4, true)

      assert  (@s11 == @r11)
      assert_equal  @s11, @r11
      assert !(@s11 == @r12)
      assert  (@s11 != @r12)
      assert_equal  @s21, t21
      assert  (@s21 ==  t21)
      assert  (@s21 != @s11)
      assert  (@s21 != @s12)
      assert  (@s21 != @s22)
      assert  (@s12 == @r12)
      assert   @s12.eql?(@r12)
      assert  (@s11 != u11)
      assert  (@s11 != v11)
      assert  (@s21 != v21)
      assert  (@s22 != v22)
      assert  (@s22 != u11)
      assert  (@s22 != 'a')

      sc1 = RangeExtd.new("D".."F", false)
      sc2 = RangeExtd("D".."F", true)
      assert (sc1 == ("D".."F"))
      assert (sc1 == RangeExtd(("D".."F")))
      assert (sc1 != sc2)
    end	# def test_eql

    def test_eql2
      assert  ((1..2) == (1..2))
      assert  ((1..2) == (1.0..2))
      assert  ((1..2).eql? (1..2))	# 1==(1.0)     == true
      assert  (1 == 1.0)
      assert !(1.eql?(1.0))
      assert !(1.0.eql?(1))
      assert !((1..2).eql? (1.0..2))	# 1.eql?(1.0)  == false
      r12 = RangeExtd(1..2, true)
      assert  (r12.eql? RangeExtd(1..2,  true))
      assert !(r12.eql? RangeExtd(1.0..2, true))
    end

    def test_eql3
      # Comparison of NOT valid Range.
      assert  ((?a...?a) == (?a...?a))
      assert  ((?a...?a) != (?c...?c))
      assert  ((?a...?a) != ("ff"..."ff"))
      assert  ((1...1) != (8...8))
      assert  ((1...1) == (1.0...1.0))
      assert  ((1...1) != (8.0...8.0))
      assert  ((nil..nil)  != (nil...nil))
      assert  ((nil...nil) == (nil...nil))
      assert_equal false, ((?a...?a) == RangeExtd(?a...?b, true))
    end

    def test_eql4
      assert_equal((NOWHERE..nil), (NOWHERE..))
      refute_equal((..nil), (..NOWHERE))
      refute_equal((..nil), (NOWHERE..))

      # The following is in fact unexpected...
      # NOWHERE behaves like nil, and so I would expect it would be the same as (nil..?a).
      # Note RangeExtd::Infinity::NEGATIVE is accepted.  It seems that
      # the begin object must have <=> method, unless it is *literally* NilClass nil.
      #
      # In this particular case, this is not a problem, because
      # NOWHERE desirably should not be used in conjunction with other objects
      # in the first place.
      assert_raises(ArgumentError, '"bad value for range" would be raised'){(NOWHERE..?a)}
    end

    def test_begin
      assert_equal(@ib, @s11.begin)
      assert_equal(@ib, @s12.begin)
      assert_equal(@ib, @s21.begin)
      assert_equal(@ib, @s22.begin)
    end

    def test_end
      assert_equal(@ie, @s11.end)
      assert_equal(@ie, @s12.end)
      assert_equal(@ie, @s21.end)
      assert_equal(@ie, @s22.end)
    end


    def test_first
      # This is the key method of this class.

      # irb> (5...8.9).last(1)	# => [8]
      # irb> (5.2..9).last(1)	# => TypeError: can't iterate from Float
      # irb> (5.2..9).first(1)	# => TypeError: can't iterate from Float
      # irb> (5.2...9).first(1)	# => TypeError: can't iterate from Float
      # irb> RangeExtd(5.2,9,:exclude_begin=>true).first(1)	# => [6]	# Not right!
      #
      assert_equal(@ib,   @s11.first)
      assert_equal(@ib,   @s12.first)
      assert_equal(@ib,   @s21.first)
      assert_equal(@ib,   @s22.first)
      assert_equal(@ib,   @s12.first(1)[0])
      assert_equal(@ib+1, @s21.first(1)[0])
      assert_equal(@ib+1, @s22.first(1)[0])

      assert_raises RangeError do
        RangeExtd(9, 3, true)
      end

      ## String
      sc1 = RangeExtd.new("D".."F", false)
      sc2 = RangeExtd.new("D".."F", true)
      assert_equal('D',  sc1.first)
      assert_equal('D',  sc2.first)
      assert_equal('E',  sc2.first(1)[0])

      ## Arbitrary Class
      sx1 = RangeExtd.new((Xs.new(3)..Xs.new(6)), true)
      assert_equal(Xs.new(3), sx1.first)
      assert_equal(Xs.new(4), sx1.first(1)[0])

      ## Float
      sf1 = RangeExtd.new((-1.4)..8, false)
      sf2 = RangeExtd.new((-1.4)..8, true)
      assert_equal(-1.4,  sf1.first)
      assert_equal(-1.4,  sf2.first)
      assert_raises TypeError do
        sf1.first(1)
      end
      assert_raises TypeError do
        sf2.first(1)
      end

      ## Infinity
      rain = RaE(InfN, InfP, true)
      assert( rain.begin.eql?(InfN) )
      assert( rain.end.eql?(  InfP) )
      assert( rain.first.eql?(InfN) )
      assert( rain.last.eql?( InfP) )
      assert_raises(TypeError){ rain.first(1) }
      # assert_raises(TypeError){ rain.last(1) }  # => infinite loop!

      ## beginless/endless
      RangeExtd.new(nil..nil, true) # used to be RangeError (in RangeExtd Ver.1), but nothing should be raised now.

      assert_raises ArgumentError do
        @s22.first(-7)	# "negative array size (or size too big)"
      end
      assert_raises TypeError do
        @s22.first('a')
      end
      assert_raises TypeError do
        @s22.first(nil)
      end

      # (..nil).first : cannot get the first element of beginless range (RangeError)
      # (2..2).first(-1) : negative array size (or size too big) (ArgumentError)
      # (2..2).first(1,2) : wrong number of arguments (given 2, expected 1) (ArgumentError)
      # (2..2).first(?a) : no implicit conversion of String into Integer (TypeError)
      # (true..true).first(1) : can't iterate from TrueClass (TypeError)
      assert_raises(RangeError){ RangeExtd::NONE.first }
      assert_equal RangeExtd::NONE, RaE(3...3, true)
      assert_equal 3, RaE(3...3, true).first, 'Alghough (3<...3) == NONE, (3<...3).first should return a value (in the same way as  (-Float::INFINITY..5).first returns -Infinity)'
      assert_raises(RangeError){ RangeExtd::NONE.first(2) }
      assert_raises(ArgumentError){ RaE(2,3,true).first(1,2) }  # Wrong number of arguments
      assert_raises(ArgumentError){ RaE(2,3,true).first(-1) }   # Negative index
    end	# def test_first


    def test_each
      ns=0; @s11.each{|i| ns+=i}
      assert_equal(@r11.reduce(:+), ns)
      ns=0; @s12.each{|i| ns+=i}
      assert_equal(@r12.reduce(:+), ns)
      ns=0; @s21.each{|i| ns+=i}
      assert_equal(((@ib+1)..@ie).reduce(:+), ns)
      ns=0; ret=@s22.each{|i| ns+=i}
      assert_equal(((@ib+1)...@ie).reduce(:+), ns)
      assert_equal(@s22, ret)
      assert(Enumerator === @s22.each)

      ## Arbitrary Class
      sx1 = RangeExtd.new(Xs.new(3), Xs.new(6), true, true)
      a=[]; sx1.each{|i| a.push(i)}
      assert_equal([Xs.new(4), Xs.new(5)], a)
    end	# def test_each


    def test_last	# Apparently it uses each() internally.
      assert_equal(@ie,   @s11.last)
      assert_equal(@ie-1, @s12.last(1)[0])
      assert_equal(@ie,   @s21.last)
      assert_equal(@ie-1, @s22.last(1)[0])
    end


    # alias to :===, :member?
    def test_include
      assert  @s11.include?(@ib)
      assert  @s11.include?(@ie)
      assert  @s12.include?(@ib)
      assert !@s12.include?(@ie)
      assert  @s12.include?(@ie-1)
      assert !@s21.include?(@ib)
      assert  @s21.include?(@ib+1)
      assert  @s21.include?(@ie)
      assert !@s22.include?(@ib)
      assert !@s22.include?(@ie)
      assert  (@s11 === @ib)
      assert !(@s21 === @ib)
      assert  (@s21 === @ib+1)
      assert !(@s22 === @ie)

      assert  (RangeExtd.new("a", "z") === "c")
      assert !(RangeExtd.new("a", "z") === "cc")	# Key! (see cover?)
      assert  (@s22 === (@ib+@ie)/2.0+0.1)	# Key! (see cover?)
      assert  (RangeExtd.new("a", "z").member?("c"))
      assert !(RangeExtd.new("a", "z").member?("cc"))
      assert !(RangeExtd.new("a", "z", 777) === "a")
      assert  (RangeExtd.new("a", "z", nil) === "a")
      assert  (RangeExtd.new("a", "z", 777) === "b")

      assert  (RaE(..nil, true) === "b")
      assert  (RaE(..nil, true) === nil)
      assert  (RangeExtd::ALL  === ?b)
      refute  (RangeExtd::NONE === ?b)
      refute  (RangeExtd::NONE === nil)     # NONE includes nothing
      refute  (RangeExtd::NONE === NOWHERE) # NONE includes nothing, even NOWHERE (because of exclude_begin/end)
    end	# def test_include


    def test_bsearch
      ary = [0, 4, 7, 10, 12]
      assert_equal(2,   RangeExtd(0, ary.size).bsearch{|i| ary[i] >= 6})
      # http://www.ruby-doc.org/core-2.1.1/Range.html#method-i-bsearch

      assert_equal(3,   RangeExtd(1..4).bsearch{   |i| ary[i] >=  9})	# (1..4).bsearch{|i| ary[i] >= 9} => 3
      assert_nil        RangeExtd(3...4).bsearch{  |i| ary[i] >= 11}
      assert_nil        RangeExtd(3.6...4).bsearch{|i| ary[i] >= 11}
      assert_equal(4,   RangeExtd(3...5).bsearch{  |i| ary[i] >= 11})
      assert_equal(4.0, RangeExtd(3...5.1).bsearch{|i| ary[i] >= 11})
      assert_nil        RangeExtd(3.6...4).bsearch{|i| ary[i] >= 11}

      assert_equal(4,   RangeExtd(3...5,   1).bsearch{  |i| ary[i] >= 11})
      assert_nil        RangeExtd(4...5,   1).bsearch{  |i| ary[i] >= 11}
      assert_equal(4.0, RangeExtd(3...5.1, 1).bsearch{|i| ary[i] >= 11})
      assert_nil        RangeExtd(3.6...4, 1).bsearch{|i| ary[i] >= 11}

      assert_raises TypeError do
        RangeExtd.new((?a..?b), :exclude_begin => true).bsearch{|i| ary[i] >= 11}
      end
    end	# def test_bsearch

    def test_bsearch_special
      sp = Special.new

      # Standard Range
      assert_nil     RangeExtd(3..4).bsearch{ |i| sp[i]}
      assert_nil     RangeExtd(3...4).bsearch{|i| sp[i]}
      assert(1e-8 > (RangeExtd(3.0...4).bsearch{|i| sp[i]} - 3.5).abs)
      assert(1e-8 > (RangeExtd(3...4.0).bsearch{|i| sp[i]} - 3.5).abs)
      assert(1e-8 > (RangeExtd(3.3..4).bsearch{ |i| sp[i]} - 3.5).abs)
 
      # RangeExtd
      assert(1e-8 > (RangeExtd(3...4.1,   1).bsearch{|i| sp[i]} - 3.5).abs)
      assert(1e-8 > (RangeExtd(3.7...4,   1).bsearch{|i| sp[i]} - 3.7).abs)
      assert(1e-8 > (RangeExtd(3.7...4.2, 1).bsearch{|i| sp[i]} - 3.7).abs)	# If end is 4.7, it will be nil (presumably due to the algorithm), whereas still 3.7 if 4.5.
    end	# def test_bsearch_special


    def test_cover
      assert  @s11.cover?(@ib)
      assert  @s11.cover?(@ie)
      assert  @s12.cover?(@ib)
      assert !@s12.cover?(@ie)
      assert  @s12.cover?(@ie-1)
      assert !@s21.cover?(@ib)
      assert  @s21.cover?(@ib+1)
      assert  @s21.cover?(@ie)
      assert !@s22.cover?(@ib)
      assert !@s22.cover?(@ie)
      st = RangeExtd.new((1.4..7), true)
      assert !(st.cover?(1.4))
      assert  (st.cover?(1.5))

      assert  (RangeExtd.new("a", "z").cover?("c"))
      assert  (RangeExtd.new("a", "z").cover?("cc"))	# Key! (see include?)
      assert  (@s22.cover?((@ib+@ie)/2.0+0.1))	# Key! (see cover?)
      su = RangeExtd.new("a", "z", 777)
      sv = RangeExtd.new("a", "z", nil)
      assert !(su.cover?("a"))
      assert  (sv.cover?("a"))
      assert  (su.cover?("b"))
    end	# def test_cover


    # No redefinition of the method, because super() works fine!
    def test_count
      assert_equal 5, RaE(1..5).count
      assert_equal 4, RaE(1...5).count
      assert_equal 3, RaE(1...5, true).count
      assert_equal 5, RaE(1...5.1).count
      assert_equal 4, RaE(1...5.1, true).count
      assert_raises(TypeError){ RaE(1.0..5).count }  # can't iterate from Float
      assert_equal 0, RaE(1..5.1).count(5.1)
      assert_equal 1, RaE(1..5.1).count(1)
      assert_equal 0, RaE(1..5.1, true).count(1)
      assert_equal 2, RaE(1..5.1).count{|i| i<3}
      assert_equal 1, RaE(1..5.1, true).count{|i| i<3}
      assert_raises(TypeError){    (..5).count{|i| i<3} }  # can't iterate from NilClass
      assert_raises(TypeError){ RaE(..5).count{|i| i<3} }
      # (1..).count{|i| i<3}  # => infinite loop
      assert_equal InfF, RaE(5..).count
      assert_equal InfF, RaE(..5).count
      assert_equal InfF,        (..nil).count
      assert_raises(TypeError){ (..nil).count(3) }  # can't iterate from NilClass
      assert_raises(TypeError){ (..nil).count{|i| i<3} }
      assert_equal InfF,    (-Float::INFINITY..nil).count
      assert_equal InfF, RaE(-Float::INFINITY..nil, true).count
      assert_raises(TypeError){    (-Float::INFINITY..Float::INFINITY).count } # can't iterate from Float (TypeError)
      assert_raises(TypeError){ RaE(-Float::INFINITY..Float::INFINITY).count }
      assert_equal InfF, RangeExtd::ALL.count  # A special case, like (..nil).
    end


    def test_hash
      assert_equal(@r11.hash, @s11.hash)
      assert_equal(@r12.hash, @s12.hash)
      refute_equal(@r12.hash, @s22.hash)
      refute_equal RangeExtd::NONE.hash,     (...nil).hash
      refute_equal RangeExtd::NONE.hash, RaE((...nil), true).hash
    end	# def test_hash

    def test_min
      assert_equal(@ib,   @s11.min)
      assert_equal(@ib,   @s12.min)
      assert_equal(@ib+1, @s21.min)
      assert_equal(@ib+1, @s22.min)

      assert_equal(@ie-1, @s22.min{|a,b| -a <=> -b})

      assert_raises(TypeError){ RangeExtd.new(1.0, 5, :exclude_begin => true).min }
      assert_raises(RangeError){ (..3).min } # cannot get the minimum of beginless range

      assert_equal(?b,    (?b...).min)
      assert_equal(?b,    (?b...InfP).min)
      assert_equal(?b, RaE(?b...InfP).min)
      assert_equal(?c, RaE(?b...InfP, true).min)
      assert_raises(RangeError){ RaE(..?z).min }
      assert_equal(-InfF, RaE(-InfF..9.2).min)
      assert_equal InfN,  RaE(InfN..?z).min
    end	# def test_min

    def test_min_by
      assert_equal(@ib+1, @s22.min_by.each{|i| i})

      assert_equal Enumerator,  RangeExtd.new(1.0, 5, true).min_by.class
      assert_raises(TypeError){ RangeExtd.new(1.0, 5, true).min_by{|i|} }
      assert_raises(TypeError){ RangeExtd.new(1.0, 5, true).min_by.each{|i| i} } # can't iterate from Float (TypeError)
      assert_equal 2,  RangeExtd.new(1..5, exclude_begin: true).min_by.each{|i| i}

      assert_equal(@ie-1, @s22.min_by{|a| -a })
    end	# def test_min_by


    def test_minmax
      assert_equal([@ib,@ie],     @s11.minmax)
      assert_equal([@ib,@ie-1],   @s12.minmax)
      assert_equal([@ib+1,@ie],   @s21.minmax)
      assert_equal([@ib+1,@ie-1], @s22.minmax)

      assert_equal([@ie-1,@ib+1], @s22.minmax{|a,b| -a <=> -b})	# Not the best test...

      assert_raises(TypeError){ RangeExtd.new(1.0, 5, true).minmax }
      assert_raises(RangeError){    (?b...).minmax } # cannot get the maximum of endless range
      assert_raises(RangeError){ RaE(?b...).minmax }
    end	# def test_minmax


    def test_minmax_by
      assert_equal([@ib+1,@ie-1], @s22.minmax_by.each{|i| i})

      assert_raises(TypeError){ (1.0...5).minmax_by{|i| } }
      assert_raises(TypeError){ RangeExtd.new(1.0, 5, true).minmax_by{|i| } }
      assert_equal Enumerator,  RangeExtd.new(1.0, 5, true).minmax_by.class

      assert_equal([@ie-1,@ib+1], @s22.minmax_by{|a| -a })
    end	# def test_minmax_by


    def test_max
      assert_raises(TypeError){ (2.0...4.9).max } # cannot exclude non Integer end value
      assert_raises(TypeError){ (1.3...5).max }   # cannot exclude end value with non Integer begin value
      assert_equal(@ie,   @s11.max)
      assert_equal(@ie-1, @s12.max)
      assert_equal(@ie,   @s21.max)
      assert_equal(@ie-1, @s22.max)

      assert_equal(@ib+1, @s22.max{|a,b| -a <=> -b})	# Not the best test...

      assert_equal 5, RaE(1.0, 5, true).max

      assert_raises(RangeError){    (...?z).max } # cannot get the maximum of beginless range with custom comparison method
      assert_raises(RangeError){ RaE(...?z, true).max }
      assert_equal(?z, RaE(InfN..?z).max)
      assert_nil  RaE(5...6, true).max
    end	# def test_max


    def test_max_by
      assert_equal(@ie-1, @s22.max_by.each{|i| i})
      assert_equal Enumerator,  RaE(1.0, 5, true).max_by.class
      assert_raises(TypeError){ RaE(1.0, 5, true).max_by{|i|} } # can't iterate from Float

      assert_equal(@ib+1, @s22.max_by{|a| -a })
      assert_equal(3, RaE(3...6).max_by{|a| -a })
    end	# def test_max_by


    def test_size
      assert_equal(@ie-@ib+1, @s11.size)
      assert_equal(@ie-@ib,   @s12.size)
      assert_equal(@ie-@ib,   @s21.size)
      assert_equal(@ie-@ib-1, @s22.size)
      assert_nil      RangeExtd("a", "c").size
      assert_equal 0, RangeExtd::NONE.size
      assert_equal Float::INFINITY, RangeExtd::ALL.size

      # Infinity
      inf = Float::INFINITY
      excl_ini = true
      assert_equal inf, RangeExtd(-inf, 1).size
      assert_raises RangeError do
        RangeExtd(-inf, -inf, excl_ini)	# exclde_begin yet !exclude_end
      end
      assert_equal inf, RangeExtd(-inf,    1, excl_ini).size
      assert_raises RangeError do
        RangeExtd( inf,  inf, excl_ini)	# exclde_begin yet !exclude_end
      end
      assert_equal inf, RangeExtd(   1,  inf, excl_ini).size

      # Float
      rfi = (2.8..4.8)	# size() => 3	see [ruby-list:49797] from matz
      rfe = (2.8...4.8)	# size() => 2
      siz = rfi.size
      assert_equal siz,   RangeExtd(rfi).size
      assert_equal siz-1, RangeExtd(rfe).size
      assert_equal siz-1, RangeExtd(rfi, excl_ini).size
      assert_equal siz-1, RangeExtd(rfe, excl_ini).size

      # Float No.2
      # @see http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/49797 [ruby-list:49797] from matz for how {Range#size} behaves (in Japanese).
      assert_equal  4, RaE(  1..5, true).size
      assert_equal  3, RaE(  1..5, true, true).size		#  (1...5).size  == 3
      assert_equal  4, RaE(Rational(1,1), 5, true, true).size   # (1/1...5).size == 4
      assert_equal  3, RaE(1..Rational(5,1), true, true).size   # (1...1/5).size == 3
      assert_equal  4, RaE(1..Rational(5,1), true, false).size  # (1..1/5).size  == 4

      assert_equal  5, RaE(0.8..5, true).size
      assert_equal  4, RaE(1.2..5, true).size
      assert_equal  4, RaE(1.5..5, true).size
      assert_equal  4, RaE(1.5..4.9, true).size
      assert_equal  3, RaE(1.5...4.5, true).size
      assert_equal  2, RaE(2.8...4.8, true).size
      assert_equal  RaE(2.8...4.8, true).size, RaE(Rational(28,10)...4.8, true).size
      assert_equal  RaE(2.8...4.8, true).size, RaE(Rational(28,10)...Rational(48,10), true).size
      assert_equal  Float::INFINITY, RaE(0..Float::INFINITY, true).size
      # (0.5...5).size			# => 5 (Ruby 2.1)
      # (Rational(1,2)...5).size	# => 4 (Ruby 2.1) =>  Bug!

      if 4.8-2.8 > 2	# => 2.0000000000000004
        assert_equal  3, RaE(2.8...4.8, true).size
      end

      # String
      rsi = (?a..?d)
      if rsi.size.nil?
        assert_nil        RangeExtd(rsi, excl_ini).size	# Ruby 2.1
      else
        assert_equal   3, RangeExtd(rsi, excl_ini).size	# If the specification ever changes?
      end
    end	# def test_size

    # Following the main doc...
    def test_size2
      assert_equal InfF, RaE(5..InfF).size
      assert_equal InfF, RaE(..?z).size            # This contradicts the specification. Should be nil.
      assert_equal InfF, RaE(...?z, true).size
      assert_equal InfF, RaE(..nil).size           # This may contradict the specification?
      assert_equal InfF, RaE(...nil, true).size
      assert_equal InfF, RaE(3.., true).size
      assert_equal InfF, RaE(..?a, true).size      # This contradicts the specification. Should be nil.
      assert_equal InfF, RaE(InfN...?a, true).size
      assert_nil         RaE(?a.., true).size
      assert_nil         RaE(?a...InfP, true).size
      assert_equal    0, RangeExtd::NONE.size  # This specification may change.
      assert_nil         RaE(?a...?a, true).size   # Any size with non-Numeric Range is nil.

      # More perplexing standard Ruby behaviours.
      # Bug #18993: https://bugs.ruby-lang.org/issues/18993
      assert_equal    3, (5.quo(3)...5).size      # => 3
      assert_equal    4, (5.quo(3).to_f...5).size # => 4
      assert_equal    4, (5.quo(3)..5).size       # => 4
      assert_equal    4, (5.quo(3).to_f..5).size  # => 4
    end	# def test_size2

    def test_step
      ns=0; @s11.step(2){|i| ns+=i}
      assert_equal(1+3+5, ns)
      ns=0; @s12.step(2){|i| ns+=i}
      assert_equal(1+3+5, ns)
      ns=0; @s21.step(2){|i| ns+=i}
      assert_equal(2+4+6, ns)
      ns=0; ret=@s22.step(2){|i| ns+=i}
      assert_equal(2+4, ns)
      assert_equal(@s22, ret)
      assert(Enumerator === @s22.step(2))

      ## Arbitrary Class
      sx1 = RangeExtd.new(Xs.new(3), Xs.new(6), true, true)
      a=[]; sx1.step(2){|i| a.push(i)}
      assert_equal([Xs.new(4)], a)
    end	# def test_step


    def test_to_s
      assert_equal 'a...c',  RangeExtd(?a...?c).to_s
      assert_equal 'a<..c',  RangeExtd(?a..?c,  true).to_s
      assert_equal 'a<...c', RangeExtd(?a...?c, true).to_s
      assert_equal '"a"<.."c"', RangeExtd(?a..?c, true).inspect
    end


    def test_Infinity
      assert  (RangeExtd::Infinity::NEGATIVE.infinity?)
      assert  (RangeExtd::Infinity::POSITIVE.infinity?)
      assert !(RangeExtd::Infinity::NEGATIVE.positive?)
      assert  (RangeExtd::Infinity::POSITIVE.positive?)
      assert  (RangeExtd::Infinity::NEGATIVE.negative?)
      assert !(RangeExtd::Infinity::POSITIVE.negative?)
      assert_equal(-1, (RangeExtd::Infinity::NEGATIVE <=> -3))
      assert_nil       (RangeExtd::Infinity::NEGATIVE <=> Object.new)
      assert_equal  0, (RangeExtd::Infinity::NEGATIVE <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> -3)
      assert_nil       (RangeExtd::Infinity::POSITIVE <=> Object.new)
      assert_equal  0, (RangeExtd::Infinity::POSITIVE <=> RangeExtd::Infinity::POSITIVE)
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal(-1, (RangeExtd::Infinity::NEGATIVE <=> RangeExtd::Infinity::POSITIVE))
      assert_equal RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::NEGATIVE
      assert_equal RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::NEGATIVE
      refute RangeExtd::Infinity::POSITIVE.respond_to? :succ
      refute RangeExtd::Infinity::NEGATIVE.respond_to? :succ
      refute_equal(-Float::INFINITY, RangeExtd::Infinity::NEGATIVE)
      refute_equal  Float::INFINITY, RangeExtd::Infinity::POSITIVE
      assert_raises(ArgumentError) { Float::INFINITY < RangeExtd::Infinity::POSITIVE }
      assert_raises(ArgumentError) { Float::INFINITY > RangeExtd::Infinity::POSITIVE }
      assert_raises(ArgumentError) { Float::INFINITY > RangeExtd::Infinity::NEGATIVE }
      assert_raises(ArgumentError) { RangeExtd::Infinity::NEGATIVE > -Float::INFINITY }
      assert_raises(ArgumentError) { RangeExtd::Infinity::NEGATIVE >  Float::INFINITY }
      assert_raises(ArgumentError) { RangeExtd::Infinity::NEGATIVE < -Float::INFINITY }
      assert_raises(ArgumentError) { RangeExtd::Infinity::POSITIVE >  Float::INFINITY }
      assert_raises(ArgumentError) { RangeExtd::Infinity::POSITIVE < -Float::INFINITY }
      #assert !(RangeExtd::Infinity::POSITIVE >  Float::INFINITY)  # Before Ver.1.1
      #assert !(RangeExtd::Infinity::NEGATIVE > -Float::INFINITY)  # Before Ver.1.1
      #assert !(RangeExtd::Infinity::POSITIVE >  Float::INFINITY)  # Before Ver.1.1
      #assert !(RangeExtd::Infinity::POSITIVE <  Float::INFINITY)  # Before Ver.1.1
      assert  (RangeExtd::Infinity::POSITIVE > 0)
      assert  (RangeExtd::Infinity::POSITIVE > RangeExtd::Infinity::NEGATIVE)
      assert  (RangeExtd::Infinity::NEGATIVE < 0)
      assert  (RangeExtd::Infinity::NEGATIVE < RangeExtd::Infinity::POSITIVE)
      assert !(RangeExtd::Infinity::POSITIVE === Object.new)
      assert !(RangeExtd::Infinity::NEGATIVE === Object.new)
      assert  (RangeExtd::Infinity::POSITIVE === RangeExtd::Infinity::POSITIVE)
      assert  (RangeExtd::Infinity::NEGATIVE === RangeExtd::Infinity::NEGATIVE)
      assert !(RangeExtd::Infinity::POSITIVE === RangeExtd::Infinity::NEGATIVE)
      assert !(RangeExtd::Infinity::NEGATIVE === RangeExtd::Infinity::POSITIVE)

      #### Comment valid up to Ver.1.0  (changed in Ver.1.1)
      #
      ## This is the case so far.  Rewrite Float/Fixnum/Bignum/Rational??
      ## It would get slow, though!  It is a lot better to use Float::INFINITY, instead.
      # assert_raises ArgumentError do
      #   Float::INFINITY == RangeExtd::Infinity::POSITIVE
      # end
    end

    def test_Infinity_from_obj
      assert_equal( 1, (?a <=> RangeExtd::Infinity::NEGATIVE))
      assert_equal(-1, (?a <=> RangeExtd::Infinity::POSITIVE))
      assert_equal( 1, (Time.now <=> RangeExtd::Infinity::NEGATIVE))
      assert_equal(-1, (Time.now <=> RangeExtd::Infinity::POSITIVE))
    end

    def test_is_infinities
      # infinity?
      refute RangeExtd::Infinity.infinity? 5
      refute RangeExtd::Infinity.infinity? InfF
      assert RangeExtd::Infinity.infinity? InfP
      assert RangeExtd::Infinity.infinity? InfN
      assert RangeExtd::Infinity.infinity? RangeExtd::ALL.begin

      # infinite?  (similar but different!)
      refute RangeExtd::Infinity.infinite? 5
      assert RangeExtd::Infinity.infinite? InfF
      assert RangeExtd::Infinity.infinite? InfP
      assert RangeExtd::Infinity.infinite? InfN
      assert RangeExtd::Infinity.infinite? RangeExtd::ALL.begin
    end

    def test_RangeExtdClass_valid
      assert RangeExtd.valid?(nil, nil, 9,9)	# All 3 were true up to Version 0.1.0 and at 2.0+
      assert RangeExtd.valid?(nil...nil,9,9)
      assert RangeExtd.valid?(nil..nil, 9,9)
    end	# def test_RangeExtdClass_valid

    def test_Range_valid
      assert  RangeExtd::NONE.valid?
      assert  RangeExtd::ALL.valid?
      assert  (1..3).valid?
      assert !(3..1).valid?
      assert  (?a..?a).valid?	# single element
      assert !(?a...?a).valid?	# less than empty
      assert  (?a...?b).valid?	# single element
      assert  (nil..nil).valid?
      assert !(true...true).valid?
      assert  RangeExtd(0..0).valid?
      #assert !RangeExtd(0...0).valid?
      assert  RangeExtd(0...0, 7).valid?
      #assert !RangeExtd(0...0, false).valid?
      #assert  RangeExtd(5..RangeExtd::Infinity::POSITIVE, nil, 7).valid?	# => ArgumentError 
      #assert  RangeExtd(5..RangeExtd::Infinity::POSITIVE).valid?	# => ArgumentError "Float::INFINITY is not comparable with other Infinity."
      #assert  RangeExtd(RangeExtd::Infinity::NEGATIVE..5, true).valid?
      #assert  RangeExtd(RangeExtd::Infinity::NEGATIVE..5).valid?
      assert  RangeExtd(?b..RangeExtd::Infinity::POSITIVE, nil, 7).valid?	# => ArgumentError 
      assert  RangeExtd(?b..RangeExtd::Infinity::POSITIVE).valid?	# => ArgumentError "Float::INFINITY is not comparable with other Infinity."
      assert  RangeExtd(RangeExtd::Infinity::NEGATIVE..?b, true).valid?
      assert  RangeExtd(RangeExtd::Infinity::NEGATIVE..?b).valid?
    end		# def test_Range_valid

    # For Ruby 2.6 and onwards
    def test_endlessRange_valid
      assert  (0..).valid?  # This raises the uncapturable SyntaxError for Ruby 2.5 and before anyway.
      assert  (0...).valid?
      refute  (true..).valid?
      assert  (nil...).valid?   # false in Ver.1 (Ruby 2.6)
      assert  (nil..nil).valid? # false in Ver.1 (Ruby 2.6)
      assert   (Float::INFINITY..Float::INFINITY).valid?
      assert  (-Float::INFINITY..Float::INFINITY).valid?
      assert  (-Float::INFINITY...Float::INFINITY).valid?
    end

    def test_Range_empty
      assert  RangeExtd::NONE.empty?
      assert !RangeExtd::ALL.empty?
      assert    !(1..3).empty?
      assert_nil (3..1).empty?
      assert    !(?a..?a).empty?	# single element
      assert_nil (?a...?a).empty?	# less than empty
      assert    !(?a...?b).empty?	# single element
      assert     RangeExtd(?a...?b, :exclude_begin => true).empty?	# empty
      refute     (nil..nil).empty?
      refute     (nil..3).empty?
      assert_nil (true...true).empty?
      assert    !RangeExtd(0..0).empty?	# single element
      assert_nil (0...0).empty?
      assert     RangeExtd(0...0, :exclude_begin => true).empty?	# empty
      assert     RangeExtd(0...1, :exclude_begin => true).empty?	# empty
      assert     RangeExtd(0.0...0, :exclude_begin => true).empty?	# empty
      assert    !RangeExtd(0.0...1, :exclude_begin => true).empty?
      #assert     RangeExtd(0...0, false).empty?	# => ArgumentError 
      assert !RangeExtd(-5, Float::INFINITY, true).empty?
      assert !RangeExtd(-5, Float::INFINITY, nil).empty?
      assert !RangeExtd(-Float::INFINITY, -5, nil, true).empty?
      assert !RangeExtd(-Float::INFINITY, -5).empty?
      assert !RangeExtd(?b, RangeExtd::Infinity::POSITIVE, true).empty?
      assert !RangeExtd(?b, RangeExtd::Infinity::POSITIVE, nil).empty?
      assert !RangeExtd(RangeExtd::Infinity::NEGATIVE, ?b, nil, true).empty?
      assert !RangeExtd(RangeExtd::Infinity::NEGATIVE, ?b).empty?
    end	# def test_Range_empty


    def test_Range_nullfunc
      assert  RangeExtd::NONE.null?
      assert !RangeExtd::ALL.null?
      assert    !(1..3).null?
      assert     (3..1).null?
      assert    !(?a..?a).null?	# single element
      assert     (?a...?a).null?	# less than empty
      assert    !(?a...?b).null?	# single element
      assert     RangeExtd(?a...?b, :exclude_begin => true).null?	# empty
      refute     (nil..nil).null?
      assert     (true...true).null?
      assert    !RangeExtd(0..0).null?	# single element
      assert     (0...0).null?
      assert     RangeExtd(0...0, :exclude_begin => true).null?	# empty
      assert     RangeExtd(0...1, :exclude_begin => true).null?	# empty
      assert     RangeExtd(0.0...0, :exclude_begin => true).null?	# empty
      assert    !RangeExtd(0.0...1, :exclude_begin => true).null?
      #assert     RangeExtd(0...0, false).null?	# => ArgumentError 
      assert !RangeExtd(-5, Float::INFINITY, true).empty?
      assert !RangeExtd(-5, Float::INFINITY, nil).empty?
      assert !RangeExtd(-Float::INFINITY, -5, nil, true).empty?
      assert !RangeExtd(-Float::INFINITY, -5).empty?
      assert !RangeExtd(?b, RangeExtd::Infinity::POSITIVE, true).empty?
      assert !RangeExtd(?b, RangeExtd::Infinity::POSITIVE, nil).empty?
      assert !RangeExtd(RangeExtd::Infinity::NEGATIVE, ?b, nil, true).empty?
      assert !RangeExtd(RangeExtd::Infinity::NEGATIVE, ?b).empty?
    end	# def test_Range_nullfunc


    def test_Range_equiv
      r1 = (2..5)
      r2 = (2...7)
      assert !r1.equiv?("Q") 
      assert !r1.equiv?(2.0..3.1) 
      assert  r1.equiv?(2.0..5.0) 
      assert  (2.0..5.0).equiv?(r1) 
      assert  (2.0..5.0).equiv?(2.0..5.0)
      assert !r1.equiv?(RangeExtd(2..5,true)) 
      assert !r1.equiv?(1..5) 
      assert  r1.equiv?(2..5) 
      assert  r2.equiv?(2...7) 
      assert  r1.equiv?(RangeExtd(1..5,true)) 
      assert !r1.equiv?(2...5) 
      assert !r2.equiv?(2..7) 
      assert !r1.equiv?(2..6) 
      assert !r2.equiv?(2...8) 
      assert  r1.equiv?(2...6) 
      assert  r1.equiv?(RangeExtd(1...6,true)) 
      assert  r2.equiv?(2..6) 
      assert  r2.equiv?(RangeExtd(1..6,true)) 
      assert !r1.equiv?(2...9) 
      assert !r2.equiv?(2..9) 
      assert !r1.equiv?(RangeExtd(1...9,true)) 
      assert !r2.equiv?(RangeExtd(1..9,true)) 
      assert  (3...7.0).equiv?(3..6)    # Because begin.succ is defined.
      assert !(3...7.0).equiv?(3.0..6)  # Because begin.succ is not defined.
    end	# def test_Range_equiv


    def test_RangeExtd_equiv
      r1 = RangeExtd(2..5)
      r2 = RangeExtd(2...7)
      r3 = RangeExtd(2..5,true)
      r4 = RangeExtd(2...7,true)
      assert !r1.equiv?("Q")
      assert !r1.equiv?(2.0..3.1)
      assert  r1.equiv?(2.0..5.0)
      assert  (2.0..5.0).equiv?(r1)
      assert  (2.0..5.0).equiv?(2.0..5.0)
      assert  r2.equiv?(2.0...7.0)
      assert  r4.equiv?(RangeExtd(2.0...7.0,true))
      assert !r1.equiv?(RangeExtd(2..5,true))
      assert !r2.equiv?(r4)
      assert !r3.equiv?(2..5)
      assert !r4.equiv?(2...7)
      assert !r1.equiv?(1..5) 
      assert !r3.equiv?(RangeExtd(1..5,true)) 
      assert !r1.equiv?(RangeExtd(4..5,true))
      assert !r3.equiv?(4..5) 
      assert  r1.equiv?(2..5)
      assert  r2.equiv?(2...7)
      assert  r1.equiv?(RangeExtd(1..5,true))
      assert  r2.equiv?(RangeExtd(1...7,true))
      assert  r3.equiv?(3..5)
      assert  r4.equiv?(3...7)
      assert !r1.equiv?(RangeExtd(1...5,true))
      assert !r2.equiv?(RangeExtd(1..7,true))
      assert !r3.equiv?(3...5)
      assert !r4.equiv?(3..7)
      assert !r1.equiv?(2..9)
      assert !r1.equiv?(RangeExtd(1..9,true))
      assert !r2.equiv?(RangeExtd(1...9,true))
      assert !r3.equiv?(3..9)
      assert !r4.equiv?(3...9)
      assert  r1.equiv?(2...6)
      assert  r1.equiv?(RangeExtd(1...6,true))
      assert  r2.equiv?(RangeExtd(1..6,true))
      assert  r3.equiv?(3...6)
      assert  r4.equiv?(3..6)
      assert !r4.equiv?(3.0..6.0)
      assert !r1.equiv?(2...9)
      assert !r1.equiv?(RangeExtd(1...9,true))
      assert !r2.equiv?(RangeExtd(1..9,true))
      assert !r3.equiv?(3...9)
      assert !r4.equiv?(3..9)
    end	# def test_RangeExtd_equiv


    # Test of Range(Extd)#is_none? and RangeExtd::NONE
    def test_RangeExtd_none
      # From examples in RangeExtd#is_none?
      assert  RaE(0,0,true,true).valid?
      assert (RaE(0,0,true,true) == RangeExtd::NONE)
      assert  RaE(0,0,true,true).empty?
      refute  RaE(0,0,true,true).is_none?

      refute  (RangeExtd( 1, 1,true,true).is_none?)
      refute  (RangeExtd(?a,?a,true,true).is_none?)
      refute  ((1...1).is_none?)

      assert  RangeExtd::NONE.is_none?
      assert  RangeExtd::NONE.valid?
      assert  RangeExtd::NONE.null?
      assert  RangeExtd::NONE.empty?
      assert_raises(RangeError){ RaE(NOWHERE...NOWHERE, true) }
      refute((NOWHERE...NOWHERE).valid?, "RangeExtd::Nowhere::NOWHERE should not reside anywhere but in RangeExtd::NONE")
      #assert_equal RaE(NOWHERE...NOWHERE, true), RangeExtd::NONE
      #refute       RaE(NOWHERE...NOWHERE, true).is_none?, "Even an equivalent RangeExtd to NONE should NOT be true==is_none?"

      assert_nil  RangeExtd::NONE.begin
      assert      RangeExtd::NONE.begin.nowhere?, "RangeExtd::NONE.begin should be RangeExtd::Nowhere::NOWHERE"
      assert_nil  RangeExtd::NONE.end
      assert      RangeExtd::NONE.end.nowhere?

      refute RaE(0...0, true).is_none?
      refute (nil..nil).is_none?
      refute (nil...nil).is_none?
      assert RaE(...nil, true).valid?
      refute RaE(...nil, true).null?
      refute RaE(...nil, true).empty?

      refute_equal RaE(0...0, true),   RaE(?a...?a, true)
      assert_equal RaE(0...1, true),   RaE(5...6, true)
      refute      (RaE(0...1, true).eql?(RaE(5...6, true)))
      assert_equal RaE(0...1, true),   RaE(1...1, true)
      assert_equal RaE(0...1, true),   RangeExtd::NONE
      assert_equal RaE(?a...?b, true), RangeExtd::NONE
      refute_equal((1...1), RangeExtd::NONE, "comparison with invalid Range should return false")
      assert_equal RaE(0, 0, true, true), RangeExtd::NONE
      assert_equal RaE(?a, ?a, true, true), RangeExtd::NONE
      assert_equal RaE(?a, ?b, true, true), RangeExtd::NONE
      assert      !RaE(?a, ?b, true, true).is_none?
      assert       RaE(?a, ?b, true, true).empty?
      assert       RaE(?a, ?b, true, true).null?

      assert( RangeExtd::NONE ==  RangeExtd::NONE )
      refute( RangeExtd::NONE === RangeExtd::NONE )
      refute_equal(   (..nil),        RangeExtd::NONE)
      refute      (RaE(...nil, true).eql?(RangeExtd::NONE))
      refute_equal(RaE(...nil, true), RangeExtd::NONE)
      refute_equal RangeExtd::NONE,    (..nil)
      refute_equal RangeExtd::NONE, RaE(...nil, true)
      refute_equal RangeExtd::NONE, RangeExtd::ALL
      refute_equal RangeExtd::ALL,  RangeExtd::NONE
      assert_equal RangeExtd::ALL, (..nil)
      assert_equal((..nil), RangeExtd::ALL)
    end


    def test_RangeExtd_empty_equal
      assert  RaE(?a, ?b, 5, 5).empty?
      assert  RaE(1, 2, 5, 5).empty?
      assert  RaE(3.0, 3.0, 5, 5).empty?
      assert  RaE(?a, ?b, 5, 5) != RaE(1, 2, 5, 5)
      assert  RaE(?a, ?b, 5, 5) == RaE(?c, ?d, 5, 5)
      assert  RaE(11, 12, 5, 5) == RaE(11, 11, 5, 5)
      assert  RaE(11, 12, 5, 5) == RaE(1, 2, 5, 5)
      refute  RaE(11, 12, 5, 5).eql?( RaE(1, 2, 5, 5) )
      assert  RaE(11, 12, 5, 5) == RaE(3.0, 3.0, 5, 5)
      refute  RaE(11, 12, 5, 5).eql?( RaE(3.0, 3.0, 5, 5) )
      #assert_equal RangeExtd::NONE, RangeExtd(0...0, :exclude_begin => true)	# => ArgumentError 
      #assert_equal RangeExtd(0...0, :exclude_begin => true), RangeExtd::NONE
    end


    def test_RangeExtd_all
      assert !RangeExtd::ALL.is_none?
      assert  RangeExtd::ALL.valid?
      assert !RangeExtd::ALL.null?
      assert !RangeExtd::ALL.empty?
      refute_equal (-Float::INFINITY..Float::INFINITY), RangeExtd::ALL
      refute_equal RangeExtd::ALL, (-Float::INFINITY..Float::INFINITY)
      assert_equal RangeExtd::Infinity::POSITIVE, RangeExtd::ALL.end
      assert_equal RangeExtd::Infinity::NEGATIVE, RangeExtd::ALL.begin
    end

    def test_RangeExtd_num
      r = RangeExtd(5, Float::INFINITY, true)
      assert       r.exclude_begin?
      assert_equal 5, r.begin
      assert_equal 5, r.first
      assert_equal [6,7,8], r.first(3)
      assert          r.cover?(1e50)
      assert         !r.cover?(4.9)
      assert         !r.cover?(5)
      assert         !(r === 5)
      assert_equal Float::INFINITY, r.end	# It is exactly Float.

      # It seems in the old versions of Ruby, Float::INFINITY.positive? was not defined,
      # as this used to give false.  As of Ruby 2.6, it is true (and it should be).
      assert (defined? Float::INFINITY.positive?), (defined? r.end.positive?)

      n = 0
      r.each{|ei| n+=ei;break if n > 20}	# [6, 7, 8, ...]
      assert_equal 21, n
      n = 0
      r.step(2){|ei| n+=ei;break if n > 20}	# [6, 7, 8, ...]
      assert_equal 24, n

      assert_raises TypeError do
        r.first(?a)
      end

      # r.last(3)  # goes into an infinite loop!
    end


    def test_RangeExtd_eql
      infF = Float::INFINITY
      assert_equal RaE(-infF, 8, nil, nil),  (-Float::INFINITY..8)
      assert_equal RaE(-infF, 8, nil, true), (-Float::INFINITY...8)
      assert_equal (-Float::INFINITY..8),  RaE(-infF, 8, nil, nil)
      assert_equal (-Float::INFINITY...8), RaE(-infF, 8, nil, true)

      assert(RaE(-infF, 8, nil, nil) != (-Float::INFINITY..9) )
      assert(RaE(-infF, 8, nil, nil) != (-Float::INFINITY...8)) 
      assert((-Float::INFINITY..8) != RaE(-infF, 8, nil, true) )
      assert((-Float::INFINITY...9)!= RaE(-infF, 8, nil, true) )

      assert_equal RaE(8, infF, nil), (8..Float::INFINITY)
      assert_equal RaE(8, infF, true), RaE(8..Float::INFINITY, true)
      assert_equal (8..Float::INFINITY), RaE(8, infF, nil)
      assert_equal RaE(8..Float::INFINITY, true), RaE(8, infF, true)

      assert(RaE(8, infF, true) != (8..Float::INFINITY))
      assert(RaE(8, infF, nil) != RaE(8..Float::INFINITY, true))
      assert((8..Float::INFINITY) != RaE(8, infF, true))
      assert(RaE(8..Float::INFINITY, true) != RaE(8, infF, nil))
    end

    def test_RangeExtd_str
      # neg = RangeExtd::Infinity::NEGATIVE
      # pos = RangeExtd::Infinity::POSITIVE
      rs = RangeExtd(RangeExtd::Infinity::NEGATIVE, 'z', nil, true)
      assert       rs.exclude_end?
      assert     ! rs.begin.positive?
      assert       rs.begin.negative?
      assert_equal 'z', rs.end
      assert_equal 'z', rs.last
      assert      !rs.cover?(?z)
      assert       rs.cover?(?x)
      assert      (rs === ?x)  # This used to be nil.
      assert_equal RangeExtd::Infinity::NEGATIVE, rs.begin	# It is Infinity,
      refute_equal(-Float::INFINITY, rs.begin)
      assert     ! rs.begin.positive?
      assert( (..?z).size == rs.size )
      #assert_raises(TypeError){ rs.last(3) }  # => infiite loop
    end

    def test_infinity_unary_operators
      assert_equal RangeExtd::Infinity::POSITIVE, +RangeExtd::Infinity::POSITIVE
      assert_equal RangeExtd::Infinity::NEGATIVE, -RangeExtd::Infinity::POSITIVE
      assert_equal RangeExtd::Infinity::NEGATIVE, +RangeExtd::Infinity::NEGATIVE
      assert_equal RangeExtd::Infinity::POSITIVE, -RangeExtd::Infinity::NEGATIVE
    end

    # Tests of all the examples in the document.
    def test_in_document
      # RangeExtd#initialize
      r = RangeExtd(5...8, true) 
      assert  r.exclude_begin?  # => true 

      # RangeExtd#==
      assert_equal RangeExtd::NONE, RaE(1,   1, T, T)	# (1<...1)   == RangeExtd::NONE # => true
      assert_equal RangeExtd::NONE, RaE(?a, ?b, T, T)	# (?a<...?b) == RangeExtd::NONE # => true
      assert_equal RaE(2, 2, T, T), RaE(1,  1, T, T)	# (1<...1) == (2<...2)     # => true
      assert_equal RaE(3, 4, T, T), RaE(1,  1, T, T)	# (1<...1) == (3<...4)     # => true
      assert_equal RaE(?c,?c,T, T), RaE(?a, ?b, T, T)	# (?a<...?b) == (?c<...?c) # => true
      assert      (RaE(?c,?c,T,T) != RaE(1, 1, T, T))	# (1<...1) != (?c<...?c)   # - because of Fixnum and String
      assert_equal RaE(3, 4, T, T), RaE(1.0, 1.0, T, T)	# (1.0<...1.0) == (3<...4) # => true

      # RangeExtd#eql?  (removed from doc)
      assert_equal (1.0...5.0), (1...5)			# (1...5) ==  (1.0...5.0)  # => true
      refute (1...5).eql?(1.0...5.0)			# (1...5).eql?(1.0...5.0)  # => false
      refute RaE(1,  1,  T,T).eql?(RangeExtd::NONE)	# (1<...1).eql?(  RangeExtd::NONE)  # => true
      refute RaE(?a, ?b, T,T).eql?(RangeExtd::NONE)	# (?a<...?b).eql?(RangeExtd::NONE)  # => true
      refute RaE(1,  1,  T,T).eql?(RaE(3,4,T,T))	# (1<...1).eql?(    3<...4)  # => true
      refute RaE(1.0,1.0,T,T).eql?(RaE(3,4,T,T))	#  (1.0<...1.0).eql?(3<...4)  # => false

      # RangeExtd#===
      assert  ((?D..?z) === ?c)

      if RUBY_VERSION < '2.7'
        assert !((?a..?z) === "cc")
        assert !((?B..?z) === 'dd')
      else
        assert  ((?a..?z) === "cc")
        assert  ((?B..?z) === 'dd')
      end

      # RangeExtd#equiv?
      assert  RangeExtd(2...7,true).equiv?(3..6)     # => true
      assert !RangeExtd(2...7,true).equiv?(3..6.0)   # => false
      assert !RangeExtd(2...7,true).equiv?(3.0..6.0) # => false
      assert !RangeExtd(2...7,true).equiv?(3..6.5)   # => false
      assert  RangeExtd(2...7,true).equiv?(RangeExtd(2.0...7.0,true))   # => true
      assert  RangeExtd(2...7,true).equiv?(3...7.0)  # => true

      # RangeExtd#eql?bsearch
      ary = [0, 4, 7, 10, 12]
      assert_nil        (3...4).bsearch{    |i| ary[i] >= 11}
      assert_equal   4, (3...5).bsearch{    |i| ary[i] >= 11}
      assert_equal 4.0, (3..5.1).bsearch{   |i| ary[i] >= 11}
      assert_equal 4.0, (3.6..4).bsearch{   |i| ary[i] >= 11}
      assert_nil        (3.6...4).bsearch{  |i| ary[i] >= 11}
      assert_equal 4.0, (3.6...4.1).bsearch{|i| ary[i] >= 11}

      sp = Special.new
      assert_nil           (3..4).bsearch{   |i| sp[i]}
      assert_nil           (3...4).bsearch{  |i| sp[i]}
      assert_equal  0,(((3.0...4).bsearch{|i| sp[i]}-3.5)*1e10.abs).to_i	# => 3.5000000000000004
      assert_equal  0,(((3...4.0).bsearch{|i| sp[i]}-3.5)*1e10.abs).to_i	# => 3.5000000000000004
      assert_equal  0,(((3.3..4).bsearch{ |i| sp[i]}-3.5)*1e10.abs).to_i	# => 3.5000000000000004

      assert_raises(TypeError){ (Rational(36,10)..5).bsearch{|i| ary[i] >= 11} }	# (Rational(36,10)..5).bsearch{|i| ary[i] >= 11}	=> # TypeError: can't do binary search for Rational (Ruby 2.1)
      assert_raises(TypeError){ (3..Rational(61,10)).bsearch{|i| ary[i] >= 11} }	# (3..Rational(61,10)).bsearch{|i| ary[i] >= 11}	=> # TypeError: can't do binary search for Fixnum (Ruby 2.1)

      # RangeExtd#cover?(i)
      assert ("a".."z").cover?("cc")	# => true
      assert (?B..?z).cover?('dd')	# => true  (though 'dd'.succ would never reach ?z)

      # RangeExtd#each
      s = ''
      (1...3.5).each{|i| s+=i.to_s}
      assert_equal '123', s	# (1...3.5).each{|i|print i}	# => '123' to STDOUT
      assert_equal Enumerator, (1.3...3.5).each.class	# (1.3...3.5).each	# => #<Enumerator: 1.3...3.5:each>
      assert_raises(TypeError){ (1.3...3.5).each{|i|print i} }	# => TypeError: can't iterate from Float

      # RangeExtd#first
      assert_equal 3.1, (1...3.1).last
      assert_equal [3], (1...3.1).last(1)

      # RangeExtd#minmax
      if RUBY_VERSION < '2.7'
        assert_equal [0, 3], (0...3.5).minmax
      else
        assert_raises(TypeError){ (0...3.5).minmax }	# => TypeError: cannot exclude non Integer end value
      end
      assert_raises(TypeError){ (1.3...5).minmax }	# => TypeError: can't iterate from Float

      # RangeExtd#size
      assert_equal 2, (1.4..2.6).size
      assert_equal 2, (1.4..2.6).size
      #     (2.5...4.5000000000000021).size  => 2
      #     (2.8...4.8000000000000021).size  => 3
      assert_equal 3, (2.8..4.8).size
      assert(RangeExtd(1..5, true, true)      == RangeExtd(Rational(1,1), 5, true, true))
      assert(RangeExtd(1..5, true, true).size != RangeExtd(Rational(1,1), 5, true, true).size)
      #    4.4 - 2.4   # => 2.0000000000000004
      #    4.8 - 2.8   # => 2.0
      assert(! RangeExtd(1..5, true, true).eql?(RangeExtd(Rational(1,1), 5, true, true)))  # => false

      assert_equal [2, 3, 4], RangeExtd(1..5, true, true).to_a      # => [2, 3, 4]
      assert_equal 3, RangeExtd(1..5, true, true).to_a.size # => 3
      assert_raises(TypeError){ RangeExtd(Rational(1,1)..5).to_a }	# => TypeError
      assert_equal 3, RangeExtd(2.4..4.4, true, true).size  # => 3
      assert_equal 2, RangeExtd(2.8..4.8, true, true).size  # => 2

      assert_equal 5, (1..5).size
      assert_equal 4, (1...5).size
      assert_equal 5, (0.8...5).size	# => 5	# Why???
      assert_equal 4, (1.2...5).size	# => 4	# Why???
      assert_equal 4, (1.2..5).size	# => 4	# Why???
      assert_equal 3, (Rational(3,2)...5).size	# => 3
      assert_equal 4, (1.5...5).size	# => 4	# Why not 3??
      assert_equal 4, (1.5...4.9).size	# => 4	# Why not 3??
      assert_equal 3, (1.5...4.5).size	# => 3
      assert_equal Float::INFINITY, (0...Float::INFINITY).size	# => Infinity
      begin
        i = (Float::INFINITY..Float::INFINITY).size
        assert_equal 0, i  # In the older versions of Ruby
      rescue # FloatDomainError: NaN  (though it was not defined in old-version Ruby!)
        assert_raises(FloatDomainError){ RangeExtd(Float::INFINITY..Float::INFINITY).size }
      end

      # RangeExtd#step	# => the same as each

      # RangeExtd.valid?
      assert  RangeExtd.valid?(nil..nil)
      assert  RangeExtd.valid?(nil...nil)
      assert  RangeExtd.valid?(0..0)         # => true
      assert !RangeExtd.valid?(0...0)        # => false
      assert !RangeExtd.valid?(0..0,  true)  # => false
      assert  RangeExtd.valid?(0...0, true)  # => true
      assert !RangeExtd.valid?(2..-1)        # => false
      assert  RangeExtd.valid?(RangeExtd::NONE)       # => true
      assert  RangeExtd.valid?(RangeExtd::ALL) # => true
      assert  RangeExtd.valid?(3..Float::INFINITY)    # => true
      assert  RangeExtd.valid?(3..Float::INFINITY, true)  # => true
      assert  RangeExtd.valid?(RangeExtd::Infinity::NEGATIVE..?d)        # => true
      assert  RangeExtd.valid?(RangeExtd::Infinity::NEGATIVE..?d, true)  # => false
	# Note the last example may change in the future release.

      # RangeExtd.middle_strings=
      arDef = ['', '', '<', '..', '.', '', '']
      assert_equal arDef, RangeExtd.middle_strings
      assert_equal "2...6",  RangeExtd(2...6).to_s
      assert_equal "2<..6",  RangeExtd(2,6,1).to_s
      assert_equal "2...6",  RangeExtd(2...6).inspect
      assert_equal "2<..6",  RangeExtd(2,6,1).inspect
      assert_equal 'a...c',  RangeExtd(?a...?c).to_s
      assert_equal 'a<..c',  RangeExtd(?a,?c,1).to_s
      assert_equal '"a"..."c"',  RangeExtd(?a...?c).inspect
      assert_equal '"a"<.."c"',  RangeExtd(?a,?c,1).inspect

      RangeExtd.middle_strings=:math
      assert_equal ['', '<=', '<', 'x', '<', '<=', ''], RangeExtd.middle_strings
      assert_equal "2<=x<6", RangeExtd(2...6).to_s
      assert_equal "2<x<=6", RangeExtd(2,6,1).to_s
      ar=['[','(in)','(ex)',', ','(ex)','(in)',']']

      RangeExtd.middle_strings=ar
      assert_equal ar, RangeExtd.middle_strings
      assert_equal "[2(in), (ex)6]", RangeExtd(2...6).to_s
      assert_equal "[2(ex), (in)6]", RangeExtd(2,6,1).to_s

      RangeExtd.middle_strings=:default  # Default
      assert_equal arDef, RangeExtd.middle_strings
      assert_equal ['', '', '<', '..', '.', '', ''], RangeExtd.middle_strings
      assert_equal "2...6",  RangeExtd(2...6).to_s
      assert_equal "2<..6",  RangeExtd(2,6,1).to_s

      # Range#==
      assert !(1...1).valid?
      assert  (nil...nil).valid?
      assert !((1...1) == RangeExtd(1, 1, true, true))	# => false.

      # Range#valid?
      assert  (nil..nil).valid?
      assert  (0..0).valid?     # => true
      assert !(0...0).valid?    # => false
      assert !(2..-1).valid?    # => false
      assert  RangeExtd(0...0, true)   # => true
      assert  (3..Float::INFINITY).valid?   # => true
      assert  RangeExtd::NONE.valid?        # => true
      assert  RangeExtd::ALL.valid?  # => true

      # Range#empty?
      refute           (nil..nil).empty?
      assert_nil       (1...1).empty?     # => nil
      assert !(1..1).empty?      # => false
      assert  RangeExtd(1...1,   true).empty? # => true
      assert  RangeExtd(1...2,   true).empty? # => true
      assert !RangeExtd(1.0...2, true).empty? # => false
      assert  RangeExtd(?a...?b, true).empty? # => true
      assert  RangeExtd::NONE.empty?          # => true

      # Range#equiv?
      assert  (3...7).equiv?(3..6)      # => true
      assert !(3...7).equiv?(3..6.0)    # => false
      assert !(3...7).equiv?(3.0..6.0)  # => false
      assert !(3...7).equiv?(3.0..6.5)  # => false
      assert  (3...7).equiv?(3.0...7.0) # => false
      assert  (3...7.0).equiv?(3..6)    # => true
      assert !(3...7.0).equiv?(3.0..6)  # => false

      # class Infinity
      assert_equal( -1, (?z <=> RangeExtd::Infinity::POSITIVE))
      assert_equal   1, (RangeExtd::Infinity::POSITIVE <=> ?z)
      assert_nil(       (50 <=> RangeExtd::Infinity::POSITIVE), 'When "range_extd/numeric" is NOT required, 50 is not comparable with POSITIVE-infinity.')
      assert_equal   1, (RangeExtd::Infinity::POSITIVE <=> 50)
    end	# def test_in_document

    # def test_RangeExtd_special
    #   # Positive Infinity (== 'z')
    #   rs = RangeExtd('w', :exclude => true, :positive => 1, :positive_infinity_object => 'z')
    #   assert       rs.exclude?
    #   assert_equal 'z', rs.end
    #   assert_equal 'w', rs.begin
    #   assert_equal 'w<..z', rs.to_s
    #   assert_equal '"w"<.."z"', rs.inspect
    #   assert_equal  Float::INFINITY, rs.size
    #   n = ''
    #   rs.step(2){|ei| n+=ei}
    #   assert_equal 'xz', n	# warning: RangeExtd#step(2) reached +Infinity.
    #   n = ''
    #   rs.each{   |ei| n+=ei}	# warning: RangeExtd#each reached +Infinity.
    #   assert_equal 'xyz', n
    # 
    #   # Negative Infinity (== 'a')
    #   rs = RangeExtd('d', :exclude => true, :positive => nil, :negative_infinity_object => 'a')
    #   assert       rs.exclude?
    #   assert_equal 'd', rs.end
    #   assert_equal 'a', rs.begin
    #   assert_equal 'a...d', rs.to_s
    #   assert_equal '"a"..."d"', rs.inspect
    #   assert_equal  Float::INFINITY, rs.size
    #   n = ''
    #   assert_raises TypeError do
    #     rs.step(2){|ei| n+=ei}
    #   end
    #   assert_raises TypeError do
    #     rs.each{   |ei| n+=ei}
    #   end
    # end


  end	# class TestUnitFoo < MiniTest::Unit::TestCase

#end	# if $0 == __FILE__


# % ruby1.8 -rlib/range_extd/range_extd.rb -e 'p RangeExtd(2.3...7,:exclude_begin=>1).first==2.3'
# ruby1.8 -rlib/range_extd/range_extd.rb -e 'i=0;p RangeExtd(1...4,:exclude_begin=>true).each{|j|i+=j};p i==5'
# ruby1.8 -rlib/range_extd/range_extd.rb -e 'p RangeExtd(-1...7,:exclude_begin=>1).min==0'          
