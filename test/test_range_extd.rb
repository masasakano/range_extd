# -*- encoding: utf-8 -*-

$stdout.sync=true
$stderr.sync=true
# print '$LOAD_PATH=';p $LOAD_PATH
arlibrelpath = []
arlibbase = %w(range_extd range_extd/infinity)	# range_extd/infinity is actually loaded from range_extd.  But by writing here, the absolute path will be displayed.

arlibbase.each do |elibbase|
  elibbase

  arAllPaths = []
  er=nil
  pathnow = nil
  (['../lib/', 'lib/', ''].map{|i| i+elibbase+'/'} + ['']).each do |dir|
    # eg., pathcand = %w(../lib/rangesmaller/ lib/rangesmaller/ rangesmaller/) + ['']
    begin
      s = dir+File.basename(elibbase)
      arAllPaths.push(s)
#print "Trying: "; puts s
      require s
      pathnow = s
      break
    rescue LoadError => er
    end
  end	# (['../lib/', 'lib/', ''].map{|i| i+elibbase+'/'} + '').each do |dir|

  if pathnow.nil?
    warn "Warning: All the attempts to load the following files have failed.  Abort..."
    warn arAllPaths.inspect
    warn " NOTE: It may be because a require statement in that file failed, 
rather than requiring the file itself.
 Check with  % ruby -r#{File.basename(elibbase)} -e p
 or maybe add  env RUBYLIB=$RUBYLIB:`pwd`"
    # p $LOADED_FEATURES.grep(/#{Regexp.quote(File.basename(elibbase)+'.rb')}$/)
    raise er
  else
#print pathnow," is loaded!\n"
    arlibrelpath.push pathnow
  end
end	# arlibbase.each do |elibbase|

print "NOTE: Library relative paths: "; p arlibrelpath
print "NOTE: Library full paths:\n"
arlibbase.each do |elibbase|
  p $LOADED_FEATURES.grep(/#{Regexp.quote(File.basename(elibbase)+'.rb')}$/)
end


#################################################
# Unit Test
#################################################

#if $0 == __FILE__
  require 'minitest/unit'
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
  T = true
  F = false

  class TestUnitFoo < MiniTest::Unit::TestCase
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

    def test_object_compare
      assert_equal 0, (3 <=> 3)
      assert_equal 1, (4 <=> 3)
      assert_equal 1, (?b <=> ?a)
      assert_equal 0, (nil <=> nil)
      assert_equal 0, (true <=> true)
      assert_equal 0, (IO <=> IO)
    end	# def test_object_compare

    def test_overwrite_compare
      assert_equal nil, (Float::INFINITY <=> RangeExtd::Infinity::POSITIVE)
      assert_equal nil, RangeExtd::Infinity.overwrite_compare(Numeric)
      assert_equal nil, (Float::INFINITY <=> RangeExtd::Infinity::POSITIVE)	# no change
      assert_equal nil, RangeExtd::Infinity.overwrite_compare(3)
      assert_equal nil, (Float::INFINITY <=> RangeExtd::Infinity::POSITIVE)	# no change
      assert_equal false, RangeExtd::Infinity.overwrite_compare(true)	# no change
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> 's')
      assert_equal(-1, ('s' <=> RangeExtd::Infinity::POSITIVE))
      assert_equal(-1, (RangeExtd::Infinity::NEGATIVE <=> 's'))
      assert_equal  1, ('s' <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal nil, RangeExtd::Infinity.overwrite_compare('s')	# no change
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> 's')
      assert_equal(-1, ('s' <=> RangeExtd::Infinity::POSITIVE))
      assert_equal(-1, (RangeExtd::Infinity::NEGATIVE <=> 's'))
      assert_equal  1, ('s' <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal nil, (RangeExtd::Infinity::POSITIVE <=> [3,5])
      assert_equal nil, ([3,5] <=> RangeExtd::Infinity::POSITIVE)	# no change
      assert_equal nil, (defined? [3,5].compare_before_infinity)
      assert_equal false, RangeExtd::Infinity.overwrite_compare([3,5])
      assert_equal false, RangeExtd::Infinity.overwrite_compare(Hash)	# no change
      c = CLComparable.new
      assert_equal 'XXX', (c <=> 7)	# Defined in this code
      assert_equal nil, (c <=> 1)	# Object#<=>
      assert_equal nil, (c <=> RangeExtd::Infinity::POSITIVE)
      assert_raises(ArgumentError){ (c..RangeExtd::Infinity::POSITIVE) }	# => bad value for range
      assert_equal true, RangeExtd::Infinity.overwrite_compare(c)
      assert_equal(-1, (c <=> RangeExtd::Infinity::POSITIVE))
return
      assert_equal  1, (c <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal 'method', (defined? c.compare_before_infinity)	# Backup of the original
      assert_equal 'XXX', (c.compare_before_infinity(7))	# Preserved.
      assert_equal 'XXX', (c <=> 7)	# Preserved.
      assert_equal nil, (c <=> 1)
      assert_equal nil, (c <=> nil)
      assert_equal :<=>,  (c <=> 8)
    end

    def test_rangeextd_new_infinity_c2
      c2 = CLC2.new
      assert_equal nil, (c2 <=> 1)	# Object#<=>
      assert_equal(-1, (c2 <=> RangeExtd::Infinity::POSITIVE))
      assert_equal  1, (c2 <=> RangeExtd::Infinity::NEGATIVE)
      r=(c2..RangeExtd::Infinity::POSITIVE)
      assert_equal RangeExtd::Infinity::POSITIVE, r.end
      r=(RangeExtd::Infinity::NEGATIVE..c2)
      assert_equal RangeExtd::Infinity::NEGATIVE, r.begin

      assert_raises(ArgumentError){ (true..RangeExtd::Infinity::POSITIVE) }	# => bad value for range
    end	# def test_rangeextd_new_infinity_c2

    def test_range_c3c4
      c3 = CLC3.new
      assert_equal nil, (c3 <=> 1)	# Object#<=>
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
      assert_equal(-1, (c3 <=> RangeExtd::Infinity::POSITIVE))
      assert_equal  1, (c3 <=> RangeExtd::Infinity::NEGATIVE)

      r=(c3..RangeExtd::Infinity::POSITIVE)
      assert_equal RangeExtd::Infinity::POSITIVE, r.end
      r=(RangeExtd::Infinity::NEGATIVE..c3)
      assert_equal RangeExtd::Infinity::NEGATIVE, r.begin
    end	# def test_rangeextd_new_infinity_c3


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

    def test_new_const
      assert_equal @s22, RangeExtd(@r12, true)
    end

    def test_new_invalid
      ae = ArgumentError
      # Wrong number of parameters
      assert_raises(ae){ RangeExtd() }
      assert_raises(ae){ RangeExtd(1,2,3,4,5) }
      assert_raises(ae){ RangeExtd(1,2,3,4,{},6) }
      assert_raises(ae){ RangeExtd(1..1,2,3,4) }
      assert_raises(ae){ RangeExtd(1..1,2,3,{},5) }

      # Wrong range (Object input)
      assert_raises(ae){ RaE(2, -1) }
      assert_raises(ae){ RaE(nil, nil) }
      assert_raises(ae){ RaE(nil, false) }
      assert_raises(ae){ RaE(?d..?a) }
      assert_raises(ae){ RaE(?a, 5) }
      assert_raises(ae){ RaE(0, 0, true, false) }
      assert_raises(ae){ RaE(0, 0, nil,  1) }
      assert_equal RangeExtd::NONE, RaE(0, 0, true, true)
      assert_equal RangeExtd::NONE, RaE(?a, ?a, true, true)
      assert_equal (0..0), RaE(0, 0, false, false)

      # Wrong range (Infinity input)
      assert_raises(ae){ RaE(?a, RangeExtd::Infinity::NEGATIVE) }
      assert_equal (RangeExtd::Infinity::NEGATIVE..?a),  RaE(RangeExtd::Infinity::NEGATIVE, ?a)
      assert_equal (RangeExtd::Infinity::NEGATIVE...?a), RaE(RangeExtd::Infinity::NEGATIVE, ?a, nil, 3)
      assert_equal (?a..RangeExtd::Infinity::POSITIVE),  RaE(?a, RangeExtd::Infinity::POSITIVE)
      assert_equal RangeExtd, RaE(?a, RangeExtd::Infinity::POSITIVE, 1).class
      assert_raises(ae){ RaE(RangeExtd::Infinity::NEGATIVE,  Float::INFINITY) }	# Float::INFINITY is an exception - you should not mix it up.
      assert_raises(ae){ RaE(-Float::INFINITY, RangeExtd::Infinity::POSITIVE) }	# Float::INFINITY is an exception - you should not mix it up.
      assert_raises(ae){ RaE(RangeExtd::Infinity::POSITIVE, ?a) }
      assert_raises(ae){      RaE(RangeExtd::Infinity::POSITIVE, RangeExtd::Infinity::NEGATIVE) }
      assert_equal RangeExtd, RaE(RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::POSITIVE).class
      assert_raises(ae){ RaE(RangeExtd::Infinity::NEGATIVE, 0, false, false) }	# For Numeric, you should use -Float::INFINITY
      assert_raises(ae){ RaE(0, RangeExtd::Infinity::POSITIVE, false, false) }	# For Numeric, you should use  Float::INFINITY
      assert_equal RangeExtd, RaE(RangeExtd::Infinity::NEGATIVE, ?a, false, false).class
      assert_equal RangeExtd, RaE(?a, RangeExtd::Infinity::POSITIVE, false, false).class
      # assert_raises(ae){ RaE(RangeExtd::Infinity::NEGATIVE, ?a, true) }	#### No exception.  Is it OK???
      # assert_raises(ae){ RaE(?a, RangeExtd::Infinity::POSITIVE, nil, 1) }	#### No exception.  Is it OK???

      # Wrong range (Range input)
      assert_raises(ae){ RangeExtd(2..-1) }
      assert_raises(ae){ RangeExtd(nil..nil) }
      assert_raises(ae){ RangeExtd(?d..?a) }

      # Range with contradictory boundary
      assert_equal ?a..?e,  RaE(?a...?e, nil, nil)
      assert_equal ?a...?e, RaE(?a..?e,  nil,   1)
      assert_equal ?a..?a,  RaE(?a...?a, nil, nil)
      assert_equal RangeExtd::NONE, RaE(?a...?a, 1, 1)
      assert_equal RangeExtd::NONE, RaE(?a..?b,  1, 1)
      assert_raises(ae){ RaE(?a..?a, true, nil) }
      assert_raises(ae){ RaE(?a..?a,  nil,   1) }
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
      assert  RangeExtd.new(b,e,:a =>5).exclude_begin?
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
      assert_raises ArgumentError do
        RangeExtd.new(nil,5)
      end
      assert_raises ArgumentError do
        RangeExtd.new(nil,5,true)
      end
    end	# def test_exclude_begin


    # Test of Range(Extd)#is_none?
    def test_is_none
      assert  (RangeExtd::NONE.is_none?)
      assert !(RangeExtd( 1, 1,true,true).is_none?)
      assert !(RangeExtd(?a,?a,true,true).is_none?)
      assert !((1...1).is_none?)
    end

    # Test of Range(Extd)#is_everything?
    def test_is_everything
      assert  (RangeExtd::EVERYTHING.is_everything?)
      assert  (RangeExtd(RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::POSITIVE).is_everything?)	# You can create it, if you want.
      assert !((RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE).is_everything?)	# Not the standard Range, though.
      assert !(RangeExtd(-Float::INFINITY, Float::INFINITY).is_everything?)	# Different from Numeric, though.
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

      assert_raises ArgumentError do
        RangeExtd(9, 3, true)
      end
      assert_raises ArgumentError do
        @s22.first(1, 3)
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

      ## Else
      assert_raises ArgumentError do
        RangeExtd.new(nil..nil, true)
      end

      assert_raises ArgumentError do
        @s22.first(-7)	# "negative array size (or size too big)"
      end
      assert_raises TypeError do
        @s22.first('a')
      end
      assert_raises TypeError do
        @s22.first(nil)
      end
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


    def test_end
      assert_equal(@ie,   @s11.end)
      assert_equal(@ie,   @s12.end)
      assert_equal(@ie,   @s21.end)
      assert_equal(@ie,   @s22.end)
    end

    def test_last	# Apparently it uses each() internally.
      assert_equal(@ie,   @s11.last)
      assert_equal(@ie-1, @s12.last(1)[0])
      assert_equal(@ie,   @s21.last)
      assert_equal(@ie-1, @s22.last(1)[0])
    end


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
    end	# def test_include


    def test_bsearch
      ary = [0, 4, 7, 10, 12]
      assert_equal(2,   RangeExtd(0, ary.size).bsearch{|i| ary[i] >= 6})
      # http://www.ruby-doc.org/core-2.1.1/Range.html#method-i-bsearch

      assert_equal(nil, RangeExtd(3...4).bsearch{  |i| ary[i] >= 11})
      assert_equal(nil, RangeExtd(3.6...4).bsearch{|i| ary[i] >= 11})
      assert_equal(4,   RangeExtd(3...5).bsearch{  |i| ary[i] >= 11})
      assert_equal(4.0, RangeExtd(3...5.1).bsearch{|i| ary[i] >= 11})
      assert_equal(nil, RangeExtd(3.6...4).bsearch{|i| ary[i] >= 11})

      assert_equal(4,   RangeExtd(3...5,   1).bsearch{  |i| ary[i] >= 11})
      assert_equal(nil, RangeExtd(4...5,   1).bsearch{  |i| ary[i] >= 11})
      assert_equal(4.0, RangeExtd(3...5.1, 1).bsearch{|i| ary[i] >= 11})
      assert_equal(nil, RangeExtd(3.6...4, 1).bsearch{|i| ary[i] >= 11})

      assert_raises TypeError do
        RangeExtd.new((?a..?b), :exclude_begin => true).bsearch{|i| ary[i] >= 11}
      end
    end	# def test_bsearch

    def test_bsearch_special
      sp = Special.new

      # Standard Range
      assert_equal(nil, RangeExtd(3..4).bsearch{ |i| sp[i]})
      assert_equal(nil, RangeExtd(3...4).bsearch{|i| sp[i]})
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


    def test_hash
      assert_equal(@r11.hash, @s11.hash)
      assert_equal(@r12.hash, @s12.hash)
      assert (@r12.hash != @s22.hash)
    end	# def test_hash

    def test_min
      assert_equal(@ib,   @s11.min)
      assert_equal(@ib,   @s12.min)
      assert_equal(@ib+1, @s21.min)
      assert_equal(@ib+1, @s22.min)

      assert_equal(@ie-1, @s22.min{|a,b| -a <=> -b})

      assert_raises TypeError do
        RangeExtd.new(1.0, 5, :exclude_begin => true).min
      end
    end	# def test_min

    def test_min_by
      assert_equal(@ib+1, @s22.min_by.each{|i| i})

      assert_raises TypeError do
        RangeExtd.new(1.0, 5, :exclude_begin => true).min_by
      end

      assert_equal(@ie-1, @s22.min_by{|a| -a })
    end	# def test_min_by


    def test_minmax
      assert_equal([@ib,@ie],     @s11.minmax)
      assert_equal([@ib,@ie-1],   @s12.minmax)
      assert_equal([@ib+1,@ie],   @s21.minmax)
      assert_equal([@ib+1,@ie-1], @s22.minmax)

      assert_equal([@ie-1,@ib+1], @s22.minmax{|a,b| -a <=> -b})	# Not the best test...

      assert_raises TypeError do
        RangeExtd.new(1.0, 5, true).minmax
      end
    end	# def test_minmax


    def test_minmax_by
      assert_equal([@ib+1,@ie-1], @s22.minmax_by.each{|i| i})

      assert_raises TypeError do
        RangeExtd.new(1.0, 5, true).minmax_by
      end

      assert_equal([@ie-1,@ib+1], @s22.minmax_by{|a| -a })
    end	# def test_minmax_by


    def test_max
      assert_equal(@ie,   @s11.max)
      assert_equal(@ie-1, @s12.max)
      assert_equal(@ie,   @s21.max)
      assert_equal(@ie-1, @s22.max)

      assert_equal(@ib+1, @s22.max{|a,b| -a <=> -b})	# Not the best test...

      assert_raises TypeError do
        RangeExtd.new(1.0, 5, true).max
      end
    end	# def test_max


    def test_max_by
      assert_equal(@ie-1, @s22.max_by.each{|i| i})

      assert_raises TypeError do
        RangeExtd.new(1.0, 5, true).max_by
      end

      assert_equal(@ib+1, @s22.max_by{|a| -a })
    end	# def test_max_by


    def test_size
      assert_equal(@ie-@ib+1, @s11.size)
      assert_equal(@ie-@ib,   @s12.size)
      assert_equal(@ie-@ib,   @s21.size)
      assert_equal(@ie-@ib-1, @s22.size)
      assert_equal nil, RangeExtd("a", "c").size
      assert_equal 0, RangeExtd::NONE.size
      assert_equal Float::INFINITY, RangeExtd::EVERYTHING.size

      # Infinity
      inf = Float::INFINITY
      excl_ini = true
      assert_equal inf, RangeExtd(-inf, 1).size
      assert_raises ArgumentError do
        RangeExtd(-inf, -inf, excl_ini)	# exclde_begin yet !exclude_end
      end
      assert_equal inf, RangeExtd(-inf,    1, excl_ini).size
      assert_raises ArgumentError do
        RangeExtd( inf,  inf, excl_ini)	# exclde_begin yet !exclude_end
      end
      assert_equal inf, RangeExtd(   1,  inf, excl_ini).size

      # Float
      rfi = (2.4..4.4)	# size() => 3	see [ruby-list:49797] from matz
      rfe = (2.4...4.4)	# size() => 2
      siz = rfi.size
      assert_equal siz,   RangeExtd(rfi).size
      assert_equal siz-1, RangeExtd(rfe).size
      assert_equal siz-1, RangeExtd(rfi, excl_ini).size
      assert_equal siz-2, RangeExtd(rfe, excl_ini).size
      assert_equal siz-1, RangeExtd(Rational(24,10)..4.4,  excl_ini).size
      assert_equal siz-2, RangeExtd(Rational(24,10)...4.4, excl_ini).size
      # (0.5...5).size			# => 5 (Ruby 2.1)
      # (Rational(1,2)...5).size	# => 4 (Ruby 2.1) =>  Bug!

      # String
      rsi = (?a..?d)
      if rsi.size.nil?
        assert_equal nil, RangeExtd(rsi, excl_ini).size	# Ruby 2.1
      else
        assert_equal   3, RangeExtd(rsi, excl_ini).size	# If the specification ever changes?
      end
    end	# def test_size


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
      assert_equal(nil,(RangeExtd::Infinity::NEGATIVE <=> Object.new))
      assert_equal  0, (RangeExtd::Infinity::NEGATIVE <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> -3)
      assert_equal nil,(RangeExtd::Infinity::POSITIVE <=> Object.new)
      assert_equal  0, (RangeExtd::Infinity::POSITIVE <=> RangeExtd::Infinity::POSITIVE)
      assert_equal  1, (RangeExtd::Infinity::POSITIVE <=> RangeExtd::Infinity::NEGATIVE)
      assert_equal(-1, (RangeExtd::Infinity::NEGATIVE <=> RangeExtd::Infinity::POSITIVE))
      assert_equal RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::NEGATIVE
      assert_equal RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::NEGATIVE
      assert_equal RangeExtd::Infinity::POSITIVE, RangeExtd::Infinity::POSITIVE.succ
      assert_equal RangeExtd::Infinity::NEGATIVE, RangeExtd::Infinity::NEGATIVE.succ
      assert_equal(-Float::INFINITY, RangeExtd::Infinity::NEGATIVE)
      assert_equal  Float::INFINITY, RangeExtd::Infinity::POSITIVE
      assert !(RangeExtd::Infinity::NEGATIVE > -Float::INFINITY)
      assert !(RangeExtd::Infinity::NEGATIVE < -Float::INFINITY)
      assert !(RangeExtd::Infinity::POSITIVE >  Float::INFINITY)
      assert !(RangeExtd::Infinity::POSITIVE <  Float::INFINITY)
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

      ## This is the case so far.  Rewrite Float/Fixnum/Bignum/Rational??
      ## It would get slow, though!  It is a lot better to use Float::INFINITY, instead.
      # assert_raises ArgumentError do
      #   Float::INFINITY == RangeExtd::Infinity::POSITIVE
      # end
    end


    def test_Range_valid
      assert  RangeExtd::NONE.valid?
      assert  RangeExtd::EVERYTHING.valid?
      assert  (1..3).valid?
      assert !(3..1).valid?
      assert  (?a..?a).valid?	# single element
      assert !(?a...?a).valid?	# less than empty
      assert  (?a...?b).valid?	# single element
      assert !(nil..nil).valid?
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


    def test_Range_empty
      assert  RangeExtd::NONE.empty?
      assert !RangeExtd::EVERYTHING.empty?
      assert    !(1..3).empty?
      assert_nil (3..1).empty?
      assert    !(?a..?a).empty?	# single element
      assert_nil (?a...?a).empty?	# less than empty
      assert    !(?a...?b).empty?	# single element
      assert     RangeExtd(?a...?b, :exclude_begin => true).empty?	# empty
      assert_nil (nil..nil).empty?
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
      assert !RangeExtd::EVERYTHING.null?
      assert    !(1..3).null?
      assert     (3..1).null?
      assert    !(?a..?a).null?	# single element
      assert     (?a...?a).null?	# less than empty
      assert    !(?a...?b).null?	# single element
      assert     RangeExtd(?a...?b, :exclude_begin => true).null?	# empty
      assert     (nil..nil).null?
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


    def test_RangeExtd_none
      assert  RangeExtd::NONE.is_none?
      assert  RangeExtd::NONE.valid?
      assert  RangeExtd::NONE.null?
      assert  RangeExtd::NONE.empty?
      assert !RangeExtd(0...0, true).is_none?
      assert !(nil..nil).is_none?
      assert !(nil...nil).is_none?
      assert_equal RaE(0...1, true), RangeExtd::NONE
      assert_equal RaE(0, 0, true, true), RangeExtd::NONE
      assert_equal RaE(?a, ?a, true, true), RangeExtd::NONE
      assert_equal RaE(?a, ?b, true, true), RangeExtd::NONE
      assert      !RaE(?a, ?b, true, true).is_none?
      assert       RaE(?a, ?b, true, true).empty?
      assert       RaE(?a, ?b, true, true).null?
      assert_equal nil, RangeExtd::NONE.begin
      assert_equal nil, RangeExtd::NONE.end
    end


    def test_RangeExtd_empty_equal
      assert  RaE(?a, ?b, 5, 5).empty?
      assert  RaE(1, 2, 5, 5).empty?
      assert  RaE(3.0, 3.0, 5, 5).empty?
      assert  RaE(?a, ?b, 5, 5) != RaE(1, 2, 5, 5)
      assert  RaE(?a, ?b, 5, 5) == RaE(?c, ?d, 5, 5)
      assert  RaE(11, 12, 5, 5) == RaE(11, 11, 5, 5)
      assert  RaE(11, 12, 5, 5) == RaE(1, 2, 5, 5)
      assert  RaE(11, 12, 5, 5).eql?( RaE(1, 2, 5, 5) )
      assert  RaE(11, 12, 5, 5) == RaE(3.0, 3.0, 5, 5)
      assert !RaE(11, 12, 5, 5).eql?( RaE(3.0, 3.0, 5, 5) )
      #assert_equal RangeExtd::NONE, RangeExtd(0...0, :exclude_begin => true)	# => ArgumentError 
      #assert_equal RangeExtd(0...0, :exclude_begin => true), RangeExtd::NONE
    end


    def test_RangeExtd_everything
      assert !RangeExtd::EVERYTHING.is_none?
      assert  RangeExtd::EVERYTHING.valid?
      assert !RangeExtd::EVERYTHING.null?
      assert !RangeExtd::EVERYTHING.empty?
      assert_equal (-Float::INFINITY..Float::INFINITY), RangeExtd::EVERYTHING
      assert_equal RangeExtd::EVERYTHING, (-Float::INFINITY..Float::INFINITY)
      assert_equal RangeExtd::Infinity::POSITIVE, RangeExtd::EVERYTHING.end
      assert_equal RangeExtd::Infinity::NEGATIVE, RangeExtd::EVERYTHING.begin
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
      assert     (! defined? r.end.positive?)
      n = 0
      r.each{|ei| n+=ei;break if n > 20}	# [6, 7, 8, ...]
      assert_equal 21, n
      n = 0
      r.step(2){|ei| n+=ei;break if n > 20}	# [6, 7, 8, ...]
      assert_equal 24, n

      assert_raises TypeError do
        dummy = r.first(?a)
      end
      assert_raises TypeError do
        dummy = r.last(3)
      end
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
      assert_equal nil, (rs === ?x)
      assert_equal RangeExtd::Infinity::NEGATIVE, rs.begin	# It is Infinity,
      assert_equal(-Float::INFINITY, rs.begin)	# but still equal to Float.
      assert     ! rs.begin.positive?
      assert_equal  Float::INFINITY, rs.size
      assert_raises TypeError do
        dummy = rs.last(3)
      end
    end


    # Tests of all the examples in the document.
    def test_indocument
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

      # RangeExtd#eql?
      assert_equal (1.0...5.0), (1...5)			# (1...5) ==  (1.0...5.0)  # => true
      assert !(1...5).eql?(1.0...5.0)			# (1...5).eql?(1.0...5.0)  # => false
      assert  RaE(1,  1,  T,T).eql?(RangeExtd::NONE)	# (1<...1).eql?(  RangeExtd::NONE)  # => true
      assert  RaE(?a, ?b, T,T).eql?(RangeExtd::NONE)	# (?a<...?b).eql?(RangeExtd::NONE)  # => true
      assert  RaE(1,  1,  T,T).eql?(RaE(3,4,T,T))	# (1<...1).eql?(    3<...4)  # => true
      assert !RaE(1.0,1.0,T,T).eql?(RaE(3,4,T,T))	#  (1.0<...1.0).eql?(3<...4)  # => false

      # RangeExtd#===
      assert  ((?D..?z) === ?c)
      assert !((?a..?z) === "cc")
      assert !((?B..?z) === 'dd')

      # RangeExtd#eql?bsearch
      ary = [0, 4, 7, 10, 12]
      assert_equal nil, (3...4).bsearch{    |i| ary[i] >= 11}
      assert_equal   4, (3...5).bsearch{    |i| ary[i] >= 11}
      assert_equal 4.0, (3..5.1).bsearch{   |i| ary[i] >= 11}
      assert_equal 4.0, (3.6..4).bsearch{   |i| ary[i] >= 11}
      assert_equal nil, (3.6...4).bsearch{  |i| ary[i] >= 11}
      assert_equal 4.0, (3.6...4.1).bsearch{|i| ary[i] >= 11}

      sp = Special.new
      assert_equal nil, (3..4).bsearch{   |i| sp[i]}
      assert_equal nil, (3...4).bsearch{  |i| sp[i]}
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
      assert_equal [0, 3], (0...3.5).minmax
      assert_raises(TypeError){ (1.3...5).minmax }	# => TypeError: can't iterate from Float

      # RangeExtd#size
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
      assert_equal 0, (Float::INFINITY..Float::INFINITY).size

      # RangeExtd#step	# => the same as each

      # RangeExtd.valid?
      assert !RangeExtd.valid?(nil..nil)     # => false
      assert !RangeExtd.valid?(nil...nil)    # => false
      assert  RangeExtd.valid?(0..0)         # => true
      assert !RangeExtd.valid?(0...0)        # => false
      assert !RangeExtd.valid?(0..0,  true)  # => false
      assert  RangeExtd.valid?(0...0, true)  # => true
      assert !RangeExtd.valid?(2..-1)        # => false
      assert  RangeExtd.valid?(RangeExtd::NONE)       # => true
      assert  RangeExtd.valid?(RangeExtd::EVERYTHING) # => true
      assert  RangeExtd.valid?(3..Float::INFINITY)    # => true
      assert  RangeExtd.valid?(3..Float::INFINITY, true)  # => true
      assert  RangeExtd.valid?(RangeExtd::Infinity::NEGATIVE..?d)        # => true
      assert  RangeExtd.valid?(RangeExtd::Infinity::NEGATIVE..?d, true)  # => false
	# Note the last example may change in the future release.

      # Range.==
      assert !(1...1).valid?
      assert !(nil...nil).valid?
      assert !((1...1) == RangeExtd(1, 1, true, true))	# => false.

      # Range.valid?
      assert !(nil..nil).valid? # => false
      assert  (0..0).valid?     # => true
      assert !(0...0).valid?    # => false
      assert !(2..-1).valid?    # => false
      assert  RangeExtd(0...0, true)   # => true
      assert  (3..Float::INFINITY).valid?   # => true
      assert  RangeExtd::NONE.valid?        # => true
      assert  RangeExtd::EVERYTHING.valid?  # => true

      # Range.empty?
      assert_equal nil, (nil..nil).empty?  # => nil
      assert_equal nil, (1...1).empty?     # => nil
      assert !(1..1).empty?      # => false
      assert  RangeExtd(1...1,   true).empty? # => true
      assert  RangeExtd(1...2,   true).empty? # => true
      assert !RangeExtd(1.0...2, true).empty? # => false
      assert  RangeExtd(?a...?b, true).empty? # => true
      assert  RangeExtd::NONE.empty?          # => true

      # class Infinity
      assert_equal  -1, (?z <=> RangeExtd::Infinity::POSITIVE)
      assert_equal   1, (RangeExtd::Infinity::POSITIVE <=> ?z)
      assert_equal nil, (50 <=> RangeExtd::Infinity::POSITIVE)
      assert_equal   1, (RangeExtd::Infinity::POSITIVE <=> 50)
    end

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
