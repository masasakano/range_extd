# -*- encoding: utf-8 -*-

## Load required files.
req_files = %w(range_extd/infinity)
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
    p $LOADED_FEATURES.grep(/#{Regexp.quote(File.basename(elibbase)+'.rb')}$/).uniq
  end
end

# =Class RangeExtd
#
# Authors:: Masa Sakano
# License:: MIT
#
# ==Summary
#
# Extended Range class that features:
#  1. includes exclude_begin? (to exclude the "begin" boundary),
#  2. allows open-ended range to the infinity (very similar to beginless/endless Range),
#  3. defines NONE and ALL constants,
#  4. the first self-consistent logical structure,
#  5. complete compatibility with the built-in Range.
#
# The instance of this class is immutable, that is, you can not
# alter the element once an instance is generated.
#
# This class has some constants
#
# What is valid is checked with the class method {RangeExtd.valid?}.
# See the document of that method for the definition.
#
# This class has two constants:
# {RangeExtd::NONE} representing an empty range and 
# {RangeExtd::ALL} representing the entire range, both in the abstract sense.
#
# @example An instance of a range of 5 to 8 with both ends being exclusive is created as
#   r = RangeExtd(5...8, true) 
#   r.exclude_begin?  # => true 
#
class RangeExtd < Range

  # To conrol how the {RangeExtd} should be displayed or set (in one form).
  # It can be read and reset by {RangeExtd.middle_strings} and
  # {RangeExtd.middle_strings=}
  # Default is +['', '', '<', '..', '.', '', '']+
  @@middle_strings = []

  # Error messages
  ERR_MSGS = {
    infinity_compare: 'Float::INFINITY is not mathematically comparable with another Infinity.',
  }
  private_constant :ERR_MSGS

  # @note The flag of exclude_begin|end can be given in the arguments in a couple of ways.
  #  If there is any duplication, those specified in the optional hash have the highest
  #  priority.  Then the two descrete Boolean parameters have the second.
  #  If not, the values embeded in the {Range} or {RangeExtd} object or the String form
  #  in the parameter are used.  In default, both of them are false.
  #
  # @example 
  #    RangeExtd(1...2)
  #    RangeExtd(1..3, true)
  #    RangeExtd(2..3, :exclude_begin => true)
  #    RangeExtd(1, 4, false, true)
  #    RangeExtd(1,'<...',5)
  #    RangeExtd.middle_strings = :math
  #    RangeExtd(2,'<x<=',5)
  #    RangeExtd(RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE)
  #
  # @overload new(range, [exclude_begin=false, [exclude_end=false]], opts)
  #   @param [Object] range Instance of {Range} or its subclasses, including {RangeExtd}
  #   @param exclude_begin [Boolean] If specified, this has the higher priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the higher priority, or false in default.
  #   @option opts [Boolean] :exclude_begin If specified, this has the highest priority, or false in default.
  #   @option opts [Boolean] :exclude_end If specified, this has the highest priority, or false in default.
  #
  # @overload new(obj_begin, obj_end, [exclude_begin=false, [exclude_end=false]], opts)
  #   @param obj_begin [Object] Any object that is +Comparable+ with end
  #   @param obj_end [Object] Any object that is Comparable with begin
  #   @param exclude_begin [Boolean] If specified, this has the lower priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the lower priority, or false in default.
  #   @option opts [Boolean] :exclude_begin If specified, this has the higher priority, or false in default.
  #   @option opts [Boolean] :exclude_end If specified, this has the higher priority, or false in default.
  #
  # @overload new(obj_begin, string_form, obj_end, [exclude_begin=false, [exclude_end=false]], opts)
  #   @param obj_begin [Object] Any object that is +Comparable+ with end
  #   @param string_form [Object] String form (without pre/postfix) of range expression set by {RangeExtd.middle_strings=}()
  #   @param obj_end [Object] Any object that is +Comparable+ with begin
  #   @param exclude_begin [Boolean] If specified, this has the lower priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the lower priority, or false in default.
  #   @option opts [Boolean] :exclude_begin If specified, this has the higher priority, or false in default.
  #   @option opts [Boolean] :exclude_end If specified, this has the higher priority, or false in default.
  #
  # Note if you use the third form with "string_form" with the user-defined string
  # (via {RangeExtd.middle_strings=}()), make 100 per cent sure you know
  # what you are doing.  If the string is ambiguous, the result may differ
  # from what you thought you would get!  See {RangeExtd.middle_strings=}() for detail.
  # Below are a couple of examples:
  #
  #   RangeExtd.new(5, '....', 6)      # => RangeError because (5..("....")) is an invalid Range.
  #   RangeExtd.new("%", '....', "y")  # => ("%" <.. "....")
  #                                    #   n.b., "y" is interpreted as TRUE for
  #                                    #   the flag for "exclude_begin?"
  #   RangeExtd.new("x", '....', "y")  # => RangeError because ("x" <..("....")) is an invalid RangeExte,
  #                                    #   in the sense String "...." is *smaller* than "x"
  #                                    #   in terms of the "<=>" operator comparison.
  #
  # @raise [ArgumentError] particularly if the range to be created is not {#valid?}.
  def initialize(*inar, **hsopt)	# **k expression from Ruby 1.9?

    # This is true only for RangeExtd::NONE,
    # which is identical to +RangeExtd(nil, nil, true, true)+ without this.
    @is_none = false

    if inar[4] == :Constant
      # Special case to create two Constants (NONE and ALL)
      @rangepart = (inar[2] ? (inar[0]...inar[1]) : (inar[0]..inar[1]))
      @exclude_end, @exclude_begin = inar[2..3]

      # In Ruby-2.7+ and hence RangeExtd Ver.2+, RangeExtd::NONE looks very similar to (nil...nil)
      # except RangeExtd::NONE.@exclude_begin == true
      @is_none = (@rangepart.begin.nil? && @rangepart.end.nil? && @exclude_begin && @exclude_end)
      raise(ArgumentError, "NONE has been already defined.") if @is_none && self.class.const_defined?(:NONE)  
      super(*inar[0..2])
      return
    end

    arout = RangeExtd.send(:_get_init_args, *inar, **hsopt)
    # == [RangeBeginValue, RangeEndValue, exclude_begin?, exclude_end?]

    ### The following routine is obsolete.
    ### Users, if they wish, should call RangeExtd::Infinity.overwrite_compare() beforehand.
    ### Or better, design their class properly in the first place!
    ### See the document in Object#<=> in this code for detail.
    #
    # # Modify (<=>) method for the given object, so that
    # # it becomes comparable with RangeExtd::Infinity,
    # # if the object is already Comparable.
    # #
    # # This must come first.
    # # Otherwise it may raise ArgumentError "bad value for range",
    # # because the native Range does not accept
    # #   (Obj.new..RangeExtd::Infinity::POSITIVE)
    # #
    # boundary = nil
    # aroutid0 = arout[0].object_id
    # aroutid1 = arout[1].object_id
    # if    aroutid0 == RangeExtd::Infinity::NEGATIVE.object_id ||
    #       aroutid0 == RangeExtd::Infinity::POSITIVE.object_id
    #   boundary = arout[1]
    # elsif aroutid1 == RangeExtd::Infinity::NEGATIVE.object_id ||
    #       aroutid1 == RangeExtd::Infinity::POSITIVE.object_id
    #   boundary = arout[0]
    # end
    # if (! boundary.nil?) && !defined?(boundary.infinity?)
    #   RangeExtd::Infinity.overwrite_compare(boundary)	# To modify (<=>) method for the given object.
    #   # Infinity::CLASSES_ACCEPTABLE ...
    # end

    if ! RangeExtd.valid?(*arout)
      raise RangeError, "the combination of the arguments does not constitute a valid RangeExtd instance."
    end

    @exclude_end   = arout.pop
    @exclude_begin = arout.pop
    artmp = [arout[0], arout[1], @exclude_end]
    @rangepart = Range.new(*artmp)
    super(*artmp)
  end	# def initialize(*inar, **hsopt)


  # true if self is identical to {RangeExtd::NONE}.
  #
  # Overwriting {Range#is_none?}
  # This is different from {#==} method!
  #
  # @example 
  #    RangeExtd(0,0,true,true).valid?    # => true
  #    RangeExtd(0,0,true,true) == RangeExtd::NONE  # => true
  #    RangeExtd(0,0,true,true).empty?    # => true
  #    RangeExtd(0,0,true,true).is_none?  # => false
  #    RangeExtd::NONE.is_none?     # => true
  def is_none?
    @is_none
  end


  # Returns true if the "begin" boundary is excluded, or false otherwise.
  def exclude_begin?
    @exclude_begin
  end

  # Returns true if the "end" boundary is excluded, or false otherwise.
  def exclude_end?
    @exclude_end
  end


  # Like {Range}, returns true only if both of them are {Range} (or its subclasses), and
  # in addition if both {#exclude_begin?} and {#exclude_end?} match (==) between the two objects.
  # For the empty ranges they are somewhat different.  In short, when both
  # of them are empty and they belong to the same Class or have common ancestors 
  # (apart from Object and BasicObject, excluding all the included modules),
  # this returns true, regardless of their boundary values.
  # And any empty range is equal to RangeExtd::Infinity::NONE.
  # 
  # Note the last example will return false for {#eql?} -- see {#eql?}
  # 
  # See {#eql?}
  # 
  # @example
  #   (1<...1)   == RangeExtd::NONE # => true
  #   (?a<...?b) == RangeExtd::NONE # => true
  #   (1<...1) == (2<...2)     # => true
  #   (1<...1) == (3<...4)     # => true
  #   (?a<...?b) == (?c<...?c) # => true
  #   (1<...1) != (?c<...?c)   # - because of Fixnum and String
  #   (1.0<...1.0) == (3<...4) # => true
  # 
  # @return [Boolean]
  def ==(r)
    _re_equal_core(r, :==)
  end	# def ==(r)

  # The same as {#==} but it uses eql?() as each comparison.
  # For the empty ranges, it is similar to {#==}, except
  # the immediate class has to agree to return true.
  # Only the exception is the comparison with RangeExtd::Infinity::NONE.
  # Therefore, 
  # @example
  #   (1...5) ==  (1.0...5.0)  # => true
  #   (1...5).eql?(1.0...5.0)  # => false
  #   (1<...1).eql?(  RangeExtd::NONE)  # => true
  #   (?a<...?b).eql?(RangeExtd::NONE)  # => true
  #   (1<...1).eql?(    3<...4)  # => true
  #   (1.0<...1.0).eql?(3<...4)  # => false
  #
  def eql?(r)
    _re_equal_core(r, :eql?)
  end	# def eql?(r)


  # If the object is open-ended to the negative (Infinity),
  # this returns nil in default, unless the given object is Numeric
  # (and comparable of Real), in which case this calls {#cover?},
  # or if self is {RangeExtd::ALL} and the object is Comparable.
  #
  # In the standard Range, this checks whether the given object is a member, hence,
  #    (?D..?z) === ?c    # => true
  #    (?a..?z) === "cc"  # => false
  # In the case of the former, after finite trials of [#succ] from ?c, it reaches the end (?z).
  # In the latter, after finit trials of [#succ] from the begin ?a, it reaches the end (?z).
  # Therefore it is theoretically possible to prove it (n.b., the actual
  # algorithm of built-in +Range#include?+ is different and cheating!
  # See below.).
  #
  # However, in the case of
  #    (?D..Infinity) === ?c
  # it can never prove ?c is a member after infinite trials of [#succ],
  # whether it starts the trials from the begin (?D) or the object (?c).
  #
  # For anything but Numeric, use {#cover?} instead.
  #
  # Note
  #    (?B..?z) === 'dd'  # => false
  # as Ruby's {Range} knows the algorithm of +String#succ+ and +String#<=>+
  # and specifically checks with it, before using +Enumerable#include?+.
  # {https://github.com/ruby/ruby/blob/trunk/range.c}
  #
  # Therefore, even if you change the definition of +String#succ+
  # so that 'B'.succ => 'dd', 'dd'.succ => 'z', as follows,
  #    class String
  #      alias :succ_orig :succ
  #      def succ
  #        if self == 'B'
  #          'dd'
  #        elsif self == 'dd'
  #          'z'
  #        else
  #          :succ_orig
  #        end
  #      end
  #    end
  # the resutl of +Range#===+ will unchange;
  #   (?B..?z) === 'dd'  # => false
  #   (?B..?z).to_a      # => ["B", "dd", "z"]
  #
  # Similarly {Range} treats String differently;
  #   (?X..?z).each do |i| print i;end  # => "XYZ[\]^_`abcdefghijklmnopqrstuvwxyz"
  #   ?Z.succ  # => 'AA'
  #
  # @param [Object] obj If this Object is a member?
  # @return [Boolean]
  def ===(obj)
    # ("a".."z")===("cc")	# => false

    return false if is_none?	# No need of null?(), supposedly!

    begin
      1.0+(obj)	# OK if Numeric.

    rescue TypeError
      # obj is not Numeric, hence runs brute-force check.
      beg = self.begin()
      if defined?(beg.infinity?) && beg.infinity? || beg == -Infinity::FLOAT_INFINITY
        return nil
        # raise TypeError "can't iterate from -Infinity"
      end

      each do |ei|
        if ei == obj
          return true
        end
      end
      false

    else
      cover?(obj)
    end
  end	# def ===(obj)

  alias :include? :===
  alias :member? :===


  # Return true if self and the other are equivalent; if [#to_a] is defined, it is similar to
  #    (self.to_a == other.to_a)
  # (though the ends are checked more rigorously), and if not, equivalent to
  #    (self == other)
  #
  # @example
  #    RangeExtd(2...7,true).equiv?(3..6)     # => true
  #    RangeExtd(2...7,true).equiv?(3..6.0)   # => false
  #    RangeExtd(2...7,true).equiv?(3.0..6.0) # => false
  #    RangeExtd(2...7,true).equiv?(3..6.5)   # => false
  #    RangeExtd(2...7,true).equiv?(RangeExtd(2.0...7.0,true))   # => true
  #    RangeExtd(2...7,true).equiv?(3...7.0)  # => true
  #
  # @param other [Range, RangeExtd]
  def equiv?(other)
    # This routine is very similar to Range#equiv? except
    # exclude_begin? in this object is always defined, hence
    # a more thorough check is needed.

    t_or_f = (defined?(self.begin.succ) && defined?(other.begin.succ) && defined?(other.end) && defined?(other.exclude_end?))
    if ! t_or_f
      return(self == other)	# succ() for begin is not defined.
    else
      # Checking the begins.
      if defined?(other.exclude_begin?)
        other_excl_beg = other.exclude_begin?
      else
        other_excl_beg = false
      end

      if (self.begin == other.begin)
        if (exclude_begin? ^! other_excl_beg)
          # Pass
        else
          return false
        end
      else
        if (exclude_begin? ^! other_excl_beg)
          return false
        elsif (exclude_begin? && (self.begin.succ == other.begin)) ||
              (other_excl_beg && (self.begin == other.begin.succ))
          # Pass
        else
          return false
        end
      end	# if (self.begin == other.begin)	# else
          
      # Now, the begins agreed.  Checking the ends.
      if (self.end == other.end)
        if (exclude_end? ^! other.exclude_end?)
          return true
        else
          return false
        end
      else	# if (self.end == other.end)
        if (exclude_end? ^! other.exclude_end?)
          return false
          # elsif defined?(other.last) && (self.last(1) == other.last(1))	# Invalid for Ruby 1.8 or earlier	# This is not good - eg., in this case, (1..5.5).equiv?(1..5.4) would return true.
          
        #   return true
        elsif (      exclude_end? && defined?(other.end.succ) && (self.end == other.end.succ)) ||
              (other.exclude_end? && defined?( self.end.succ) && (self.end.succ == other.end))
          return true
        else
          return false
        end
      end	# if (self.end == other.end)
    end	# if ! t_or_f
  end	# def equiv?(other)


  # @return [Object]
  def begin()
    @rangepart.begin()
  end

  # @return [Object]
  def end()
    @rangepart.end()
  end

  # bsearch is internally implemented by converting a float into 64-bit integer.
  # The following examples demonstrate what is going on.
  # 
  #    ary = [0, 4, 7, 10, 12]
  #    (3...4).bsearch{    |i| ary[i] >= 11}	# => nil
  #    (3...5).bsearch{    |i| ary[i] >= 11}	# => 4   (Integer)
  #    (3..5.1).bsearch{   |i| ary[i] >= 11}	# => 4.0 (Float)
  #    (3.6..4).bsearch{   |i| ary[i] >= 11}	# => 4.0 (Float)
  #    (3.6...4).bsearch{  |i| ary[i] >= 11}	# => nil
  #    (3.6...4.1).bsearch{|i| ary[i] >= 11}	# => 4.0 (Float)
  # 
  #    class Special
  #      def [](f)
  #       (f>3.5 && f<4) ? true : false
  #      end
  #    end
  #    sp = Special.new
  #    (3..4).bsearch{   |i| sp[i]}	# => nil
  #    (3...4).bsearch{  |i| sp[i]}	# => nil
  #    (3.0...4).bsearch{|i| sp[i]}	# => 3.5000000000000004
  #    (3...4.0).bsearch{|i| sp[i]}	# => 3.5000000000000004
  #    (3.3..4).bsearch{ |i| sp[i]}	# => 3.5000000000000004
  #
  #    (Rational(36,10)..5).bsearch{|i| ary[i] >= 11}	=> # TypeError: can't do binary search for Rational (Ruby 2.1)
  #    (3..Rational(61,10)).bsearch{|i| ary[i] >= 11}	=> # TypeError: can't do binary search for Fixnum (Ruby 2.1)
  #
  # +Range#bsearch+ works only with Integer and/or Float (as in Ruby 2.1), not even Rational (as in Ruby 3.1).
  # If either of begin and end is a Float, the search is conducted in Float and the returned value will be a Float, unless nil.
  # If Float, it searches on the binary plane.
  # If Integer, the search is conducted on the descrete Integer points only,
  # and no search will be made in between the adjascent integers.
  #
  # Given that, {RangeExtd#bsearch} follows basically the same, even when exclude_begin? is true.
  # If either end is Float, it searches between begin*(1+Float::EPSILON) and end.
  # If both are Integer, it searches from begin+1.
  # When {#exclude_begin?} is false, {RangeExtd#bsearch} is identical to +Range#bsearch+.
  #
  def bsearch(*rest, &bloc)
    if is_none?	# No need of null?(), supposedly!
      raise TypeError, "can't do binary search for NONE range"
    end

    if @exclude_begin
      if ((Float === self.begin()) ||
          (Integer === self.begin()) && (Float === self.end()))
        #NOTE: Range#bsearch accepts Infinity, whether it makes sense or not.
        # if Infinity::FLOAT_INFINITY == self.begin()
        #   raise TypeError, "can't do binary search from -Infinity"
        # else
          Range.new(self.begin()*(Float::EPSILON+1.0), self.end, exclude_end?).send(__method__, *rest, &bloc)
          # @note Technically, if begin is Rational, there is no strong reason it should not work.
          #   However Range#bsearch does not accept Rational (at Ruby 2.1), hence this code.
          #   Users should give a RangeExtd with begin being Rational.to_f in that case.
        # end
      elsif (defined? self.begin().succ)	# Both non-Float
        Range.new(self.begin().succ, self.end, exclude_end?).send(__method__, *rest, &bloc)	# In practice it will not raise an Exception, only when both are Integer.
      else
        @rangepart.send(__method__, *rest, &bloc)	# It will raise an exception anyway!  Such as, (Rational..Rational)
      end
    else
      @rangepart.send(__method__, *rest, &bloc)
    end
  end	# def bsearch(*rest, &bloc)


  # See {#include?} or {#===}, and +Range#cover?+
  def cover?(i)
    # ("a".."z").cover?("cc")	# => true
    # (?B..?z).cover?('dd')	# => true  (though 'dd'.succ would never reach ?z)

    return false if is_none?	# No need of null?(), supposedly!

    if @exclude_begin && self.begin == i
      false
    else
      @rangepart.send(__method__, i)
    end
  end	# def cover?(i)


  # slightly modified for {#exclude_begin?} being true
  #
  # @raise [TypeError] If {#exclude_begin?} is true, and {#begin}() (+@rangepart+) does not have a method of [#succ], then even if no block is given, this method raises TypeError straightaway.
  # @return [RangeExtd] self
  # @return [Enumerator] if block is not given.
  def each(*rest, &bloc)
    # (1...3.5).each{|i|print i}	# => '123' to STDOUT
    # (1.3...3.5).each	# => #<Enumerator: 1.3...3.5:each>
    # (1.3...3.5).each{|i|print i}	# => TypeError: can't iterate from Float
    # Note: If the block is not given and if @exclude_begin is true, the self in the returned Enumerator is not the same as self here.

    _step_each_core(__method__, *rest, &bloc)
  end

  # Core routine for {#each} and {#step}
  #
  # @raise [TypeError] If {#exclude_begin?} is true, and {#begin}() or {#rangepart} does not have a method of [#succ], then even if no block is given, this method raises TypeError straightaway.
  # @return [RangeExtd] self
  # @return [Enumerator] if block is not given.
  def _step_each_core(method, *rest, &bloc)
    raise TypeError, "can't iterate for NONE range" if is_none?

    if block_given?
      # when a block is given to {#each}, self should be returned.
      _converted_rangepart(consider_exclude_begin: true, raises: true ).send(method, *rest, &bloc)
      self
    else
      _converted_rangepart(consider_exclude_begin: true, raises: false).send(method, *rest)
    end
  end
  private :_step_each_core

  # Like +Range#last+, if no argument is given, it behaves like {#begin}(), that is, it returns the initial value, regardless of {#exclude_begin?}.
  #
  # If an argument is given (nb., acceptable since Ruby 1.9.2) when {#exclude_begin?} is true, it returns the array that starts from {#begin}().succ(), in the same way as +Range#last+ with {#exclude_end?} of +true+.
  #
  # The default behaviours are:
  #
  #   (1...3.1).last	# => 3.1
  #   (1...3.1).last(1)	# => [3]
  #   (1...3.0).last(1)	# => [2]
  #   (3.0..8).first(1) # raise: can't iterate from Float (TypeError)
  #
  # @raise [TypeError] if the argument (Numeric) is given and if {#exclude_begin?} is true, yet if {#begin}().succ is not defined, or yet if {#is_none?}
  # @raise [RangeError] "cannot get the first element of beginless range" as per Range.
  # @raise [ArgumentError] if more than 1 arguments are specified (delegated to {Range})
  # @param rest [Integer] Optional.  Must be non-negative.  Consult +Range#first+ for detail.
  # @return [Object] if no argument is given, equivalent to {#end}.
  # @return [Array] if an argument is given.
  def first(*rest)
    if is_none?
      raise RangeError, "cannot get the first element of RangeExtd::NONE"
    end

    ran = _converted_rangepart(transform_to_nil: false, consider_exclude_begin: (1 == rest.size && exclude_begin?))
    ran.send(__method__, *rest)
  end	# def first(*rest)


  # When {#exclude_begin?} is true, the returned value is not strictly guaranteed to be unique, though in pracrtice it is most likely to be so.
  # 
  def hash(*rest)
    if @exclude_begin
      @rangepart.send(__method__, *rest) - 1
    else
      @rangepart.send(__method__, *rest)
    end
  end


  # Return eg., '("a"<..."c")', '("a"<.."c")', if {#exclude_begin?} is true,
  # or else, identical to those for {Range}.
  # @return [String]
  def inspect
    re_inspect_core(__method__)
  end

  # Return eg., "(a<...c)", "(a<..c)", if {#exclude_begin?} is true,
  # or else, identical to those for {Range}.
  # @return [String]
  def to_s
    re_inspect_core(__method__)
  end


  # Updated version of +Range#last+, considering {#exclude_begin?}.
  #
  # If either (let alone both) side of the edge is Infinity, you can not give
  # an argument in practice, the number of the members of the returned array.
  #
  # @raise [TypeError] If self.begin.succ is not defined, or if either side is Infinity.
  # @return [Object] if no argument is given, equivalent to {#end}.
  # @return [Array] if an argument is given.
  def last(*rest)
    if is_none?
      raise RangeError, "cannot get the last element of RangeExtd::NONE"
    end

    _converted_rangepart(transform_to_nil: false).send(__method__, *rest)
  end	# def last(*rest)


  # Converts RangeExtd::Infinity to nil in @rangepart
  #
  # @param consider_exclude_begin [Boolean] If true (Default), and if {#exclude_begin?} is true, the first element is ignored.  Note the resultant Range may be +invalid+.
  # @param transform_to_nil [Boolean] If true (Default), {RangeExtd::Infinity} objects are transformed into nil when appropriate (i.e., {RangeExtd::Infinity::NEGATIVE} should be {RangeExtd#begin} and not at the end, and vice versa).
  # @param raises [Boolean] If true (Def: false), and if {#exclude_begin?} is true but [#succ] is not defined for {#begin}, this routine raises an Exception as per (almost) Ruby default.
  # @return [Range]
  def _converted_rangepart(consider_exclude_begin: true, transform_to_nil: true, raises: false)
    rbeg = @rangepart.begin
    if consider_exclude_begin && exclude_begin?
      if rbeg.respond_to? :succ
        rbeg = rbeg.succ
      elsif raises
        if rbeg.nil?
          raise RangeError, "cannot get the first element of beginless range"
        elsif is_none?	# No need of null?(), supposedly!
          raise RangeError, "cannot get the first element of NONE range"
        else
          # This includes {RangeExtd::Infinity} class objects (RangeExtd::Infinity.infinity?(rbeg) == true) and Float::INFINITY.
          raise TypeError, "can't iterate from "+self.begin.class.name
        end
      end
    end

    rbeg = nil if RangeExtd::Infinity::NEGATIVE == rbeg && transform_to_nil
    rend = @rangepart.end
    rend = nil if RangeExtd::Infinity::POSITIVE == rend && transform_to_nil

    Range.new(rbeg, rend, exclude_end?)
  end
  private :_converted_rangepart

  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def min(*rest, &bloc)
    _re_min_max_core(__method__, *rest, &bloc)
  end

  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def min_by(*rest, &bloc)
    _re_min_max_core(__method__, *rest, &bloc)
  end


  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def minmax(*rest, &bloc)
    # (0...3.5).minmax	# => [0, 3]
    # (1.3...5).minmax	# => TypeError: can't iterate from Float
    # Note that max() for the same Range raises an exception.
    # In that sense, it is inconsistent!
    _re_min_max_core(__method__, *rest, &bloc)
  end

  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def minmax_by(*rest, &bloc)
    # (0...3.5).minmax	# => [0, 3]
    # Note that max() for the same Range raises an exception.
    # In that sense, it is inconsistent!
    _re_min_max_core(__method__, *rest, &bloc)
  end


  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def max(*rest, &bloc)
    _re_min_max_core(__method__, *rest, &bloc)
  end

  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def max_by(*rest, &bloc)
    _re_min_max_core(__method__, *rest, &bloc)
  end


  # Implementation of +Range#size+ to this class.
  #
  # It is essentially the same, but the behaviour when {#exclude_begin?} is true
  # may not always be natural.
  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  # +Range#size+ only works for Numeric ranges.
  # And in +Range#size+, the value is calculated when the initial value is
  # non-Integer, by stepping by 1.0 from the {#begin} value, and the returned
  # value is an integer.
  # For example,
  #    (1.4..2.6).size == 2
  # because both 1.4 and 2.4 (== 1.4+1.0) are included in the Range.
  #
  # That means you had better be careful with the uncertainty (error)
  # of floating-point.  For example, at least in an environment,
  #     4.8 - 4.5   # => 0.2999999999999998
  #     (2.5...4.5000000000000021).size  => 2
  #     (2.8...4.8000000000000021).size  => 3
  #     (2.8..4.8).size  => 3
  #
  # In {RangeExtd#size}, the principle is the same.  If the {#begin} value has
  # the method [#succ] defined, the object is regarded to consist of
  # discrete values.  If not, it is a range with continuous elements.
  # This dinstinguishment affects the behavious seriously in some cases
  # when {#exclude_begin?} is true.  For example, the following two cases
  # may seem unnatural.
  #    RangeExtd(1..5, true, true)      == RangeExtd(Rational(1,1), 5, true, true)
  #    RangeExtd(1..5, true, true).size != RangeExtd(Rational(1,1), 5, true, true).size
  #
  # Although those two objects are equal by [#==], they are different
  # in nature, as far as {Range} and {RangeExtd} are concerned,
  # and that is why they work differently;
  #    RangeExtd(1..5, true, true).eql?(RangeExtd(Rational(1,1), 5, true, true))  # => false
  #    RangeExtd(1..5, true, true).to_a      # => [2, 3, 4]
  #    RangeExtd(1..5, true, true).to_a.size # => 3
  #    RangeExtd(Rational(1,1)..5).to_a   # => TypeError
  #
  # Also, the floating-point uncertainties in Float can more often be
  # problematic; for example, in an environment,
  #    4.4 - 2.4   # => 2.0000000000000004
  #    4.8 - 2.8   # => 2.0
  #    RangeExtd(2.4..4.4, true, true).size  # => 3
  #    RangeExtd(2.8..4.8, true, true).size  # => 2
  # The last example is what you would naively expect, because both
  #    2.8+a(lim a->0)  and  3.8+a(lim a->0) are
  # in the range whereas 4.8 is not in the range by definition,
  # but not the example right above.
  #
  # === Ruby 2.6 Endless Range and Infinity.
  #
  # Before RangeExtd Ver.1.1, if a {RangeExtd} object contains
  # {RangeExtd::Infinity} objects for either begin or end, {#size} used to
  # be always +Float::INFINITY+ no matter what the other object is
  # (except when the other object is also a {RangeExtd::Infinity} object).
  # However, since the introduction of the endless Range in Ruby 2.6,
  # Ruby returns as follows:
  #
  #   (5..).size  # => Float::INFINITY
  #   (?a..).size # => nil
  #
  # Accordingly, this class {RangeExtd} now behaves the same as Ruby (2.6 or later).
  #
  # Similarly,
  #
  #   (Float::INFINITY..Float::INFINITY).size
  #
  # has changed (I do not know in which Ruby version)!
  # It used to be 0 (in Ruby-2.1).  However, As of Ruby 2.6, it is +FloatDomainError: NaN+
  # Again this class now follows Ruby's default ({RangeExtd} Ver.1.0 or later).
  #
  # @note When both ends n are the same INFINITY (of the same parity),
  #   +(n..n).size+ used to be 0.  As of Ruby 2.6, it is FloatDomainError: NaN.
  #   This routine follows what Ruby produces, depending on Ruby's version it is run on.
  #
  # @see http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/49797 [ruby-list:49797] from matz for how +Range#size+ behaves (in Japanese).
  #
  # @return [Integer]  0 if {RangeExtd::NONE}
  # @return [Float]  Float::INFINITY if either (or both) the end is infinity, regardless of the class of the elements. 
  # @return [nil] if the range is non-Numeric.
  # @raise [FloatDomainError] (Infinity..Infinity).size (as in Ruby-3.1, though it used to be 0 in Ruby-2.1)
  def size(*rest)
    # (1..5).size	# => 5
    # (1...5).size	# => 4
    # (0.8...5).size	# => 5	# Why???
    # (1.2...5).size	# => 4	# Why???
    # (1.2..5).size	# => 4	# Why???
    # (Rational(3,2)...5).size	# => 3
    # (1.5...5).size	# => 4	# Why not 3??
    # (1.5...4.9).size	# => 4	# Why not 3??
    # (1.5...4.5).size	# => 3
    # (0...Float::INFINITY).size	# => Infinity

    return 0 if is_none?	# No need of null?(), supposedly!
      
    if self.begin.nil? || self.end.nil?   # RangeExtd#begin/end can be nil only in Ruby-2.7+/2.6+
      # Behaves as Ruby does -
      #  Infinity::FLOAT_INFINITY for Numeric and nil, but nil for any other
      #  {#exclude_end?} does not matter.
      return (self.begin..self.end).size
    end

    rbeg = self.begin
    rend = self.end

    # Either or both sides are (general or Float) Infinity
    if RangeExtd::Infinity.infinite?(rbeg) || RangeExtd::Infinity.infinite?(rend)
      return @rangepart.send(__method__, *rest)  # delegates to {Range#size}
    end

    return @rangepart.send(__method__, *rest) if !exclude_begin?

    # Now, {#exclude_begin?} is true:
    begin
      _dummy = 1.0 + rbeg	# _dummy to suppress warning: possibly useless use of + in void context
    rescue TypeError
      # Non-Numeric
      if defined? rbeg.succ
        return Range.new(rbeg.succ, rend, exclude_end?).send(__method__, *rest)	# => nil in Ruby 2.1+
      else
        return nil	# See the line above.
        # raise TypeError, "can't iterate from "+self.begin.class.name
      end
    end

    # Numeric
    if rbeg.respond_to? :succ
      Range.new(rbeg.succ, rend, exclude_end?).send(__method__, *rest)
    else
      size_no_exclude = Range.new(rbeg, rend).send(__method__, *rest)	# exclude_end? == true, ie., Range with both ends inclusinve.
      diff = self.end - self.begin
      if diff.to_i == diff		# Integer difference
        return size_no_exclude - 1	# At least exclude_begin?==true (so exclude_end? does not matter)
      else
        return size_no_exclude
      end
    end
  end	# def size


  # See {#each}.
  #
  # @raise [TypeError] If {#exclude_begin?} is true, and {#begin}() does not have the method [#succ], then even if no block is given, this method raises TypeError straightaway.
  # @return [RangeExtd] self
  # @return [Enumerator] if block is not given.
  def step(*rest, &bloc)
    _step_each_core(__method__, *rest, &bloc)
  end


  ##################################################
  # Class methods
  ##################################################

  # Private class method to evaluate the arguments.
  #
  # @note The specification changed from RangeExtd Ver.1 to Ver.2.
  #    In Ver.1 or earlier, this returns [begin, end, exclude_end, exclude_begin]
  #    In Ver.2+, this returns [begin, end, exclude_begin, exclude_end]
  #    Notice the third and fourth elements are swapped. Now it is in line
  #    with {RangeExtd.new}.
  #
  # @param (see RangeExtd#initialize) (or valid)
  # @raise [ArgumentError] if the input format is invalid (otherwise the caller may raise RangeError (it depends))
  # @return [Array<Object, Object, Boolean, Boolean>] 4-compoents: [begin, end, exclude_begin, exclude_end]
  def self._get_init_args(*inar, **hsopt)
    nMin = 1; nMax = 5
    if inar.size < nMin || nMax < inar.size
      raise ArgumentError, "wrong number of arguments (#{inar.size} for #{nMin}..#{nMax})"
    end

    hsFlag = { :prm1st => nil, :excl_offset => nil }
    if    defined? inar[0].exclude_begin?
      hsFlag[:prm1st] = :rangeextd
    elsif defined? inar[0].exclude_end?
      hsFlag[:prm1st] = :range
    else
      hsFlag[:prm1st] = :object
    end

    case hsFlag[:prm1st]
    when :rangeextd, :range
      if inar.size > 1
        exclude_begin = (true ^! inar[1])
      elsif :rangeextd == hsFlag[:prm1st]
        exclude_begin = inar[0].exclude_begin?
      else
        exclude_begin = false
      end

      if inar.size > 2
        exclude_end   = (true ^! inar[2])
      else
        exclude_end   = inar[0].exclude_end?
      end

      nMin = 1; nMax = 3
      if inar.size > nMax
        raise ArgumentError, "wrong number of arguments (#{inar.size} for #{nMin}..#{nMax})"
      end

      beginend = [inar[0].begin, inar[0].end]

    when :object
      nMin = 2; nMax = 5
      if inar.size < 2
        raise ArgumentError, "wrong number of arguments (#{inar.size} for #{nMin}..#{nMax})"
      end

      # Default: assuming the form (obj_begin, obj_end, [excl_begin, [excl_end]])
      beginend = [inar[0], inar[1]]
      hsFlag[:excl_offset] = 0
      exclude_begin = false
      exclude_end   = false

      # Now, checking if the form is the String one, and if so, process it.
      arMid = @@middle_strings.map{|i| Regexp.quote(i)}	# See self.middle_strings=(ary) for description.

      # Originally, defined?(inar[1].=~) seemed enough.  But as of Ruby 2.6 (maybe even before),
      # Numeric has :=~ method as well!
      if (inar.size > 2 &&
          inar[1].respond_to?(:=~) &&
          inar[1].respond_to?(:to_str))
        begin
          cmp = (inar[0] <=> inar[2]).abs
        rescue
          cmp = nil
        end
        if ((cmp == 0)||(cmp == 1)) && (inar[1] =~ /^(#{arMid[1]}|#{arMid[2]})#{arMid[3]}(#{arMid[4]}|#{arMid[5]})$/)
          # The form is (obj_begin, midStr, obj_end, [excl_begin, [excl_end]])
          # Hence all the default values are overwritten.
          beginend = [inar[0], inar[2]]
          hsFlag[:excl_offset] = 1
          exclude_begin = ($1 != @@middle_strings[1])
          exclude_end   = ($2 == @@middle_strings[4])
        else
          nMin = 2; nMax = 4
          if inar.size > nMax
            raise ArgumentError, "wrong number of arguments (#{inar.size} for #{nMin}..#{nMax})"
          end
        end
      else
        nMin = 2; nMax = 4
        if inar.size > nMax
          raise ArgumentError, "wrong number of arguments (#{inar.size} for #{nMin}..#{nMax})"
        end
      end

      if inar.size > 2+hsFlag[:excl_offset]
        exclude_begin = (true ^! inar[2+hsFlag[:excl_offset]])	# 3rd or 4th argument
      end

      if inar.size > 3+hsFlag[:excl_offset]
        exclude_end   = (true ^! inar[3+hsFlag[:excl_offset]])	# 4th or 5th argument
      end

    else
      raise	# (for coding safety)
    end		# case hsFlag[:prm1st]

    if hsopt.has_key?(:exclude_begin)
      exclude_begin = (hsopt[:exclude_begin] && true)
    end
    if hsopt.has_key?(:exclude_end)
      exclude_end   = (hsopt[:exclude_end] && true)
    end

    # [RangeBeginValue, RangeEndValue, exclude_begin?, exclude_end?]
    _normalize_infinity_float(beginend) + [exclude_begin, exclude_end]
  end	# def self._get_init_args(*inar)
  private_class_method :_get_init_args	# From Ruby 1.8.7 (?)

  # Replaces {RangeExtd::Infinity} with {Float::INFINITY} when appropriate
  #
  # @param beginend [Array] 2-compoents(begin, end)
  # @return [Array] 2-compoents(begin, end)
  def self._normalize_infinity_float(beginend)
    is_begin_inf = Infinity.infinity?(beginend[0])
    return beginend if is_begin_inf ^! Infinity.infinity?(beginend[1])

    # Now, only one of them is a {RangeExtd::Infinity} type object.
    if is_begin_inf && beginend[1].respond_to?(:divmod)
      [_normalize_infinity_float_core(beginend[0]), beginend[1]] # "begin" is Infinity
    elsif beginend[0].respond_to?(:divmod)
      [beginend[0], _normalize_infinity_float_core(beginend[1])] # "end" is Infinity
    else
      beginend
    end
  end
  private_class_method :_normalize_infinity_float  # From Ruby 1.8.7 (?)

  # @param inf [RangeExtd::Infinity]
  # @return [RangeExtd::Infinity, Float] +/-Float::INFINITY if Float
  def self._normalize_infinity_float_core(inf)
    msg = 'RangeExtd component of the RangeExtd::Infinity object replaced with Float::INFINITY.'
    warn msg if $DEBUG || $VERBOSE
    (inf.positive? ? 1 : -1) * Float::INFINITY
  end
  private_class_method :_normalize_infinity_float_core  # From Ruby 1.8.7 (?)


  # Returns true if the range to be constructed (or given) is valid,
  # as a range, accepted in {RangeExtd}.
  #
  # This routine is also implemented as a method in {Range},
  # and accordingly its sub-classes.
  #
  # This routine is called from {RangeExtd.new}, hence
  # for any instance of {RangeExtd} class, its {#valid?} returns true.
  #
  # What is valid is defined as follows:
  #
  # 1. The {#begin} and {#end} elements must be Comparable to each other,
  #    and the comparison results must be consistent betwen the two.
  #    The three exceptions are {RangeExtd::NONE} and Beginless and Endless Ranges
  #    introduced in Ruby 2.7 and 2.6, respectively (see below for the exceptions),
  #    which are all valid.  Accordingly, +(nil..nil)+ is
  #    valid in {RangeExtd} Ver.1.0+ (nb., it used to raise Exception in Ruby 1.8).
  # 2. Except for {RangeExtd::NONE} and Beginless Range, {#begin} must have the method +<=+.
  #    Therefore, some Endless Ranges (Ruby 2.6 and later) like +(true..)+ are *not* valid.
  #    Note even "+true+" has the method +<=>+ and hence checking +<=+ is essential.
  # 3. Similarly, except for {RangeExtd::NONE} and Endless Range, {#end} must have the method +<=+.
  #    Therefore, some Beginless Ranges (Ruby 2.7 and later) like +(..true)+ are *not* valid.
  # 4. {#begin} must be smaller than or equal to {#end},
  #    that is, ({#begin} <=> {#end}) must be either -1 or 0.
  # 5. If {#begin} is equal to {#end}, namely, ({#begin} <=> {#end}) == 0,
  #    the exclude status of the both ends must agree, except for the cases
  #    where both {#begin} and {#end} ani +nil+ (beginless and endless Range).
  #    In other words, if the {#begin} is excluded, {#end} must be also excluded,
  #    and vice versa.
  #    For example, +(1...1)+ is NOT valid for this reason,
  #    because any built-in Range object has the exclude status
  #    of +false+ (namely, inclusive) for {#begin}, whereas
  #    +RangeExtd(1...1, true)+ is valid and equal (+==+) to
  #    {RangeExtd::NONE}.
  #
  # Note the last point may change in the future release.
  #
  # Note ([2]..[5]) is NOT valid, because Array does not include Comparable
  # for some reason, as of Ruby 2.1.1, even though it has the redefined
  # and working [#<=>].  You can make those valid, by including Comparable
  # in Array class, should you wish.
  #
  # @example
  #
  #    RangeExtd.valid?(nil..nil)     # => true
  #    RangeExtd.valid?(nil...nil)    # => true
  #    RangeExtd.valid?(nil<..nil)    # => true
  #    RangeExtd.valid?(nil<...nil)   # => true
  #    RangeExtd.valid?(0..0)         # => true
  #    RangeExtd.valid?(0...0)        # => false
  #    RangeExtd.valid?(0...)         # => true
  #    RangeExtd.valid?(true..)       # => false
  #    RangeExtd.valid?(0..0,  true)  # => false
  #    RangeExtd.valid?(0...0, true)  # => true
  #    RangeExtd.valid?(2..-1)        # => false
  #    RangeExtd.valid?(RangeExtd::NONE)     # => true
  #    RangeExtd.valid?(RangeExtd::ALL)      # => true
  #    RangeExtd.valid?(3..Float::INFINITY)  # => true
  #    RangeExtd.valid?(3..Float::INFINITY, true)  # => true
  #    RangeExtd.valid?(RangeExtd::Infinity::NEGATIVE..?d)        # => true
  #    RangeExtd.valid?(RangeExtd::Infinity::NEGATIVE..?d, true)  # => true
  #
  # @note The flag of exclude_begin|end can be given in the arguments in a couple of ways.
  #  If there is any duplication, those specified in the optional hash have the highest
  #  priority.  Then the two descrete Boolean parameters have the second.
  #  If not, the values embeded in the {Range} or {RangeExtd} object
  #  in the parameter are used.  In default, both of them are false.
  #
  # @overload valid?(range, [exclude_begin=false, [exclude_end=false]])
  #   @param range [Object] Instance of Range or its subclasses, including RangeExtd
  #   @param exclude_begin [Boolean] If specified, this has the higher priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the higher priority, or false in default.
  #
  # @overload valid?(obj_begin, obj_end, [exclude_begin=false, [exclude_end=false]])
  #   @param obj_begin [Object] Any object that is +Comparable+ with end
  #   @param obj_end [Object] Any object that is +Comparable+ with begin (or nil, for Ruby 2.6 onwards)
  #   @param exclude_begin [Boolean] If specified, this has the lower priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the lower priority, or false in default.
  #
  def self.valid?(*inar)
    (vbeg, vend, exc_beg, exc_end) = _get_init_args(*inar)

    if defined?(inar[0].is_none?) && inar[0].is_none? && exc_beg && exc_end
      return true
    elsif vbeg.nil? && vend.nil?
      return true
    end

    return false if !vbeg.respond_to?(:<=>)
    begin
      t = (vbeg <=> vend)
      begin
        if vbeg.nil?  # Beginless Range introduced in Ruby 2.7
          return vend.respond_to?(:<=)
        elsif vend.nil?
          begin
            _ = (vbeg..nil)  # Endless Range introduced in Ruby 2.6
            return vbeg.respond_to?(:<=)
          rescue ArgumentError
            # Before Ruby 2.6
            return false
          end
        end
        return false if !vend.respond_to?(:<=>)
        return false if t != -1*(vend <=> vbeg)	# false if not commutative (n.b., an exception should not happen).
      rescue NoMethodError, TypeError
        if (Float === vend && defined?(vbeg.infinity?) && vbeg.infinity?) ||
           (Float === vbeg && defined?(vend.infinity?) && vend.infinity?)
          warn self.const_get(:ERR_MSGS)[:infinity_compare] if !$VERBOSE.nil?  # one of the tests comes here.
        end
        return false	# return
      end
    rescue
      warn "This should not happen. Contact the code developer (warn01)."
      false	# return
    else
      case t
      when -1
        true
      when 0
        if defined?(vbeg.<=) && defined?(vend.<=)	# Comparable?
          ((true && exc_beg) ^! exc_end)	# True if single value or empty, false if eg, (1...1)
        else
          false		# Not Comparable
        end
      when 1
        false
      else
        warn "This should not happen. Contact the code developer (warn02)."
        if (Float === vend && defined?(vbeg.infinity?) && vbeg.infinity?) ||
           (Float === vbeg && defined?(vend.infinity?) && vend.infinity?)
          warn self.const_get(:ERR_MSGS)[:infinity_compare] if !$VERBOSE.nil?  # not tested so far?
        end
        false	# Not Comparable.
      end	# case t
      # All statements of return above.
    end
  end	# def valid?

  # Set the class variable to be used in {RangeExtd#to_s} and {RangeExtd#inspect}
  # to configure the format of their returned values.
  #
  # The parameters should be given as an Array with 7 elements of string
  # in principle, which gives the characters for each index:
  # 0. prefix
  # 1. begin-inclusive
  # 2. begin-exclusive
  # 3. middle-string to bridge both ends
  # 4. end-exclusive
  # 5. end-inclusive
  # 6. postfix
  #
  # If the elements [1] and [2], or [4] and [5] are equal,
  # a warning is issued as some of {RangeExtd} in display will be indistinguishable.
  # Note even if no warning is issued, that does not mean all the forms
  # will be not ambiguous.  For example, if you specify
  #   ['(', '', '.', '..', '.', '', ')']
  # a string (3...7) can mean either exclusive {#begin} or {#end}.
  # It is user's responsibility to make it right.
  #
  # The two most popular forms can be given as a Symbol instead of Array, that is,
  #   :default  ( ['', '', '<', '..', '.', '', ''] )
  #   :math     ( ['', '<=', '<', 'x', '<', '<=', ''] )
  #
  # @param ary [Array, Symbol]
  # @return [Array, Symbol]
  #
  # @example
  #    RangeExtd.middle_strings=:default  # Default
  #    RangeExtd(2...6).to_s    # => "2...6"
  #    RangeExtd(2,6,1).to_s    # => "2<..6"
  #    RangeExtd.middle_strings=:math
  #    RangeExtd(2...6).to_s    # => "2<=x<6"
  #    RangeExtd(2,6,1).to_s    # => "2<x<=6"
  #    RangeExtd.middle_strings=['[','(in)','(ex)',', ','(ex)','(in)',']']
  #    RangeExtd(2...6).to_s    # => "[2(in), (ex)6]"
  #    RangeExtd(2,6,1).to_s    # => "[2(ex), (in)6]"
  #
  def self.middle_strings=(ary)
    case ary
    when :default
      @@middle_strings = ['', '', '<', '..', '.', '', '']
    when :math
      @@middle_strings = ['', '<=', '<', 'x', '<', '<=', '']
    else
      begin
        if ary.size == 7
          _dummy = 'a' + ary[6]
          @@middle_strings = ary
          if (ary[1] == ary[2]) || (ary[4] == ary[5])
            warn "warning: some middle_strings are indistinguishable."
          end
        else
          raise
        end
      rescue
        raise ArgumentError, "invalid argument"
      end
    end
  end

  # See {RangExtd.middle_strings=}() for detail.
  #
  # @return [Array<String>]
  def self.middle_strings()
    @@middle_strings
  end

  self.middle_strings=:default	# Initialisation

  ##################################################
  private
  ##################################################

  # Core routine for {#inspect} and {#to_s}
  # @param [Symbol] method the method name.
  def re_inspect_core(method)
    # 0. prefix
    # 1. begin-inclusive
    # 2. begin-exclusive
    # 3. middle-string to bridge both ends
    # 4. end-exclusive
    # 5. end-inclusive
    # 6. postfix

    midStr = ''
    if @exclude_begin
      midStr += @@middle_strings[2]
    else
      midStr += @@middle_strings[1]
    end
    midStr += @@middle_strings[3]
    if @exclude_end
      midStr += @@middle_strings[4]
    else
      midStr += @@middle_strings[5]
    end

    if is_none?
      strBegin = 'Null'		# Null<...Null
      strEnd   = 'Null'
    else
      strBegin = self.begin.send(method)
      strEnd   = self.end.send(method)
    end

    @@middle_strings[0] + strBegin + midStr + strEnd + @@middle_strings[6]
  end	# def re_inspect_core(method)

  # Core routine for {#inspect} and {#to_s}
  # @param [Symbol] method the method name.
  def re_inspect_core_orig(method)
    if @exclude_end
      midStr = "..."
    else
      midStr = ".."
    end
    if is_none?
      'Null' + '<' + midStr + 'Null'	# Null<...Null
    elsif @exclude_begin
      self.begin.send(method) + '<' + midStr + self.end.send(method)
    else
      self.begin.send(method) + midStr + self.end.send(method)
    end
  end	# def re_inspect_core_orig(method)


  # Core routine for {#===} and {#eql?}
  # @param [Object] r to compare.
  # @param [Symbol] method of the method name.
  def _re_equal_core(r, method)
    return false if !r.respond_to? :empty?  # Not Range family.
    return false if !r.respond_to? :exclude_end?  # Not Range family.

    is_r_empty = r.empty?
    return true if is_none? && is_r_empty	# RangeExtd::NONE
    return true if empty? && r.respond_to?(:is_none?) && r.is_none?	# r is RangeExtd::NONE

    if empty?   && is_r_empty
      if method == :eql?
        # More strict
        if self.begin().class == r.begin().class
          return true	#     (1<...1).eql? (2<...2)	# => true  (Fixnum <-> Fixnum) Yes!
        else
          return false	# (1.0<...1.0).eql? (2<...2)	# => false (Float  <-> Fixnum) No!
        end
      else
        (self.begin.class.ancestors - self.begin.class.included_modules - [Object, BasicObject]).each do |ec|
          if ec === r.begin
            return true	# (1.0<...1.0) == (2<...2)	# (Float<Numeric <-> Fixnum<Numeric) Yes!
          end
        end
        return false	#    (?a...?a) != (2<...2)	# (String <-> Numeric) No!
      end
    end

    return false if !(self.exclude_end? ^! r.exclude_end?)

    # Neither self nor r is guaranteed to be RangeExtd::NONE
    is_nil_equal = _both_eqleql_nil?(r, method)

    if defined? r.exclude_begin? # r is RangeExtd
      (self.exclude_begin? ^! r.exclude_begin?) &&
        (self.exclude_end? ^! r.exclude_end?) &&
        (self.begin.send(method, r.begin) && self.end.send(method, r.end) || is_nil_equal)
    else 
      # r is Range
      if self.exclude_begin?
        false
      else
        is_nil_equal || @rangepart.send(method, r)	# Comparison as two Range-s.
      end
    end
  end	# def _re_equal_core(r, method)
  private :_re_equal_core

  # Core routine for {#min}, {#max}, {#minmax} etc.
  # @param method [Symbol] of the method name.
  # @param rest [Object]
  def _re_min_max_core(method, *rest, &bloc)
    # (1...3.5).max	# => TypeError: cannot exclude non Integer end value
    if is_none?
      raise TypeError, "no meaningful range."
    elsif @exclude_begin
      if defined?(self.begin.infinity?) && self.begin.infinity? || self.begin == -Infinity::FLOAT_INFINITY
        raise TypeError, "can't exclude "+self.begin.to_s
      elsif ! defined? self.begin.succ
        raise TypeError, "can't iterate from "+self.begin.class.name
      else
        Range.new(self.begin.succ, self.end, exclude_end?).send(method, *rest, &bloc)
      end
    else
      @rangepart.send(method, *rest)
    end
  end	# def _re_min_max_core(method, *rest, &bloc)
  private :_re_min_max_core

  self.remove_const :NONE if defined? self::NONE  # tricky manoeuvre for documentation purposes... (see infinity.rb for the explanatory document)
  # No range.
  # In Ruby1.8, this causes  ArgumentError: bad value for range (because (nil..nil) is unaccepted).
  NONE = RangeExtd.new(nil, nil, true, true, :Constant)

  self.remove_const :ALL if defined? self::ALL  # tricky manoeuvre for documentation purposes... (see infinity.rb for the explanatory document)
  # Range covers everything.
  ALL  = RangeExtd.new(Infinity::NEGATIVE, Infinity::POSITIVE, false, false, :Constant)

end	# class RangeExtd < Range


#= Class Range
#
#== Summary
#
# Modifies {#==}, {#eql?} and add methods of
# {#valid?}, {#empty?}, {#null?}, {#is_none?} and {#is_all?}.
#
class Range

  alias_method :equal_prerangeextd?, :==  if ! self.method_defined?(:equal_prerangeextd?)	# No overwriting.

  # It is extended to handle {RangeExtd} objects.
  # For each element, that is, +Range#begin+ and +Range#end+,
  # this uses their method of ==().  See {#eql?}.
  #
  # As long as the comparison is limited within {Range} objects,
  # the returned value of this method has unchanged.
  #
  # A note of caution is, some ranges which the built-in Range accepts,
  # are now regarded as NOT valid, such as, (1...1) and (nil..nil)
  # (the latter was not permitted in Ruby 1.8), though you can still
  # use them;
  #    (1...1).valid?   # => false
  # On the other hand, {RangeExtd} class does not accept or create
  # any invalid range; for any {RangeExtd} object, RangeExtd#valid?
  # returns true.  For example, there is no {RangeExtd} object
  # that is expressed as (1...1) (See {#valid?} for detail).
  #
  # For that reason, when those non-valid Range objects are compared
  # with a {RangeExtd} object, the returned value may not be what
  # you would expect.  For example,
  #    (1...1) == RangeExtd(1, 1, true, true)  # => false.
  # The former is an invalid range, while the latter is
  # a rigidly-defined empty range.
  #
  # Consult {#valid?} and {RangeExtd#==} for more detail.
  def ==(r)
    _equal_core(r, :==, :equal_prerangeextd?)
  end


  alias_method :eql_prerangeextd?, :eql?  if ! self.method_defined?(:eql_prerangeextd?)	# No overwriting.

  # Same as {#==}, but the comparison is made with eql?() method.
  def eql?(r)
    _equal_core(r, :eql?, :eql_prerangeextd?)
  end

  alias_method :size_prerangeextd?, :size  if ! self.method_defined?(:size_prerangeextd?) # No overwriting.

  # {RangeExtd::Infinity} objects are considered
  #
  # Other than those, identical to the original {Range#size}
  #
  # Size is tricky. For example, +(nil..).size+ should be nil according to the specification
  # {https://ruby-doc.org/core-3.1.2/Range.html#method-i-size}
  # but it returns Float::INFINITY (in Ruby-3.1)
  #
  # See {RangeExtd#size} for more in-depth discussion.
  #
  # @return [Integer, NilClass]
  # @raise [FloatDomainError] +(Infinity..Infinity).size+ (as in Ruby-3.1, though it used to be 0 in Ruby-2.1)
  def size(*rest)
    rbeg = self.begin
    rend = self.end

    # Both sides are (general) Infinity
    if (rbeg.respond_to?(:infinity?) && rbeg.infinity? && 
        rend.respond_to?(:infinity?) && rend.infinity?)
      if    rbeg.negative? && rend.positive? 
        # should be nil according to the specification
        #  https://ruby-doc.org/core-3.1.2/Range.html#method-i-size
        # but this returns Float::INFINITY (in Ruby-3.1)
        return (nil..).size
      elsif rbeg.positive? && rend.negative? 
        return (Float::INFINITY..(-Float::INFINITY)).size
      else
        ## NOTE:
        # (Infinity..Infinity) => 0                 (as in Ruby 2.1)
        # (Infinity..Infinity) => FloatDomainError  (as in Ruby 3.1)
        return (Float::INFINITY..Float::INFINITY).size
      end
    end

    # Checking Infinities.
    #
    if    rbeg.respond_to?(:infinity?) && rbeg.infinity?  # but not self.end!
      return (..rend).size
    elsif rend.respond_to?(:infinity?) && rend.infinity?  # but not self.begin!
      return (rbeg..).size
    end

    size_prerangeextd?(*rest)
  end # def size(*rest)


  # Returns true if self is valid as a comparable range.
  #
  # See {RangeExtd.valid?} for the definition of what is valid
  # and more examples.
  #
  # See {#empty?} and {#null?}, too.
  # 
  # @example
  #    (nil..nil).valid? # => false
  #    (0..0).valid?     # => true
  #    (0...0).valid?    # => false
  #    (2..-1).valid?    # => false
  #    RangeExtd(0...0, true)   # => true
  #    (3..Float::INFINITY).valid?  # => true
  #    RangeExtd::NONE.valid?       # => true
  #    RangeExtd::ALL.valid?        # => true
  # 
  # @note By definition, all the {RangeExtd} instances are valid,
  #  because {RangeExtd.initialize} (+RangeExtd.new+) checks the validity.
  def valid?
    RangeExtd.valid?(self)
  end	# def valid?


  # Returns true if self is empty.
  # Returns nil if self is not valid (nb., any RangeExtd instance is valid.)
  # Otherwise false.
  #
  # The definition of what is empty is as follow.
  #
  # 1. the range must be valid: {#valid?} => true
  # 2. if it is either a beginless or endless Range, returns false.
  # 3. if the range id discrete, that is, +#begin+ has
  #    +#succ+ method, there must be no member within the range: 
  #    returns +Range#to_a.empty?+
  # 4. if the range is continuous, that is, +#begin+ does not have
  #    +#succ+ method, +#begin+ and +#end+ must be equal
  #    ((+#begin+ <=> +#end+) => 0) and both the boundaries must
  #    be excluded: ({RangeExtd#exclude_begin?} && +#exclude_end?+) == +true+.
  #    Note that ranges with equal +#begin+ and +#end+ with
  #    inconsistent two exclude status are not valid, and the built-in
  #    Range always has the "begin-exclude" status of false.
  #
  # In these conditions, none of Range instance would return true in {#empty?}.
  #
  # @example
  #   (nil..nil).empty?  # => false
  #   (nil..3).empty?    # => false
  #   (1...1).empty?     # => nil
  #   (1..1).empty?      # => false
  #   RangeExtd(1...1,   true).empty? # => true
  #   RangeExtd(1...2,   true).empty? # => true
  #   RangeExtd(1.0...2, true).empty? # => false
  #   RangeExtd(?a...?b, true).empty? # => true
  #   RangeExtd::NONE.empty?          # => true
  #
  # @note to check whether it is either empty or invalid, use {#null?}.
  # See {#valid?} and {RangeExtd.valid?}, too.
  #
  # @return [Boolean, nil]
  def empty?
    # This is basically for the sake of sub-classes, as any built-in Range instance
    # always returns either nil or false.

    if !valid?
      return nil
    elsif respond_to?(:is_none?) && is_none?
      # RangeExtd::NONE
      return true
    elsif self.begin.nil? || self.end.nil?
      return false
    end

    t = (self.begin() <=> self.end())
    case t
    when -1
      if (defined?(self.exclude_begin?)) &&
          exclude_begin? &&
          exclude_end? &&
          defined?(self.begin().succ) &&
          (self.begin().succ == self.end())
        true	# e.g., ("a"<..."b")
      else
        false
      end
    when 0
      if defined?(self.boundary) && self.boundary.nil?
        # RangeExtd::NONE or RangeExtd::All
        if self.exclude_end?
          true	# RangeExtd::NONE, though this should have been already recognized.
        else
          false	# RangeExtd::ALL
        end
      else
        if defined?(self.exclude_begin?)
          t2 = self.exclude_begin?
        else
          t2 = false	# == return false
        end
        (t2 && exclude_end?)
      end
    when 1
      nil	# redundant, as it should not be valid in the first place.
    else
      nil	# redundant, as it should not be valid in the first place.
    end
  end	# def empty?


  # Returns true if it is either empty or invalid.  false otherwise.
  #
  # See {#empty?} and {#valid?}.
  #
  # Even {RangeExtd} (with {RangeExtd#is_none?} being false) can be +null+.
  def null?
    (! valid?) || empty?
  end

  # This method is overwritten in {RangeExtd}
  # 
  # @return [FalseClass]
  def is_none?
    false
  end

  # true only if self is eql? to RangeExtd::ALL
  #
  # true if self is identical ({#eql?}) to {RangeExtd::ALL}
  #
  # (This is different from {#==}.)
  #
  # @example
  #    (RangeExtd(RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE).is_all?
  #      # => false because it is NOT RangeExtd
  def is_all?
    return false if !respond_to?(:exclude_begin?)  # Must be RangeExtd
    return false if exclude_begin? || exclude_end?
    return false if is_none?  # Essential! (b/c RangeExtd::NONE.is_all? looks like (nil..nil))

    (self.begin.eql?(RangeExtd::Infinity::NEGATIVE) && self.end.eql?(RangeExtd::Infinity::POSITIVE))
  end

  # true if self is equivalent to {RangeExtd::ALL}
  #
  # @example
  #    (RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE).equiv_all?  # => true
  #    (nil..nil).equiv_all?  # => true
  #    (nil...nil).equiv_all? # => false
  def equiv_all?
    return false if respond_to?(:is_none?) && is_none?  # Essential! (b/c RangeExtd::NONE.is_all? looks like (nil..nil))
    return false if exclude_end?
    return false if respond_to?(:exclude_begin?) && exclude_begin?

    (self.begin == RangeExtd::Infinity::NEGATIVE || self.begin.nil? || self.begin == -Float::INFINITY) &&
    (self.end   == RangeExtd::Infinity::POSITIVE || self.end.nil?   || self.end   ==  Float::INFINITY)
  end


  # Return true if self and the other are equivalent; if [#to_a] is defined, it is similar to
  #    (self.to_a == other.to_a)
  # (though the ends are checked more rigorously), and if not, equivalent to
  #    (self == other)
  #
  # @example
  #    (3...7).equiv?(3..6)      # => true
  #    (3...7).equiv?(3..6.0)    # => false
  #    (3...7).equiv?(3.0..6.0)  # => false
  #    (3...7).equiv?(3..6.5)    # => false
  #    (3...7).equiv?(3.0...7.0) # => true
  #    (3...7.0).equiv?(3..6)    # => true
  #    (3...7.0).equiv?(3.0..6)  # => false
  #
  # @param other [Range, RangeExtd]
  def equiv?(other)
    t_or_f = (defined?(self.begin.succ) && defined?(other.begin.succ) && defined?(other.end) && defined?(other.exclude_end?))
    if ! t_or_f
      return(self == other)	# succ() for begin is not defined.
    else
      # Checking the begins.
      if defined?(other.exclude_begin?) && other.exclude_begin?	# The other is RangeExtd with exclude_begin?==true.
        if self.begin != other.begin.succ
          return false
        else
          # Pass
        end
      elsif (self.begin != other.begin)
        return false
      end

      # Now, the begins agreed.  Checking the ends.
      if (self.end == other.end)
        if (exclude_end? ^! other.exclude_end?)
          return true
        else
          return false
        end
      else	# if (self.end == other.end)
        if (exclude_end? ^! other.exclude_end?)
          return false
        elsif (      exclude_end? && defined?(other.end.succ) && (self.end == other.end.succ)) ||
              (other.exclude_end? && defined?( self.end.succ) && (self.end.succ == other.end))
          return true
        else
          return false
        end
      end	# if (self.end == other.end)
    end	# if ! t_or_f

  end	# def equiv?(other)


  ############## pravate methods of Range ##############

  private

  # True if obj is Comparable.
  def is_comparable?(obj)
    defined?(obj.<=)	# Comparable?
  end

  # @param r [Object] to compare.
  # @param method [Symbol] of the method name.
  # @param method_pre [Symbol] of the backed-up original method name.
  def _equal_core(r, method, method_pre)
    if (! defined? r.exclude_end?) || (! defined? r.is_none?) || (! defined? r.empty?)
      return false	# Not Range family.
    end

    # If r is RangeExtd, this delegates the judgement to r;
    # n.b., :== and :eql? are overwritten in RangeExtd and hence this method
    # is never called when self is a RangeExtd.
    return r.send(method, self) if r.respond_to?(:exclude_begin?)

    # r is guaranteed to be a Range.
    # Neither self nor r is guaranteed to be RangeExtd (or RangeExtd::NONE)
    (_both_eqleql_nil?(r, method) && (self.exclude_end? ^! r.exclude_end?)) || self.send(method_pre, r)
  end	# def _equal_core(r, method, method_pre)
  private :_equal_core

  # true if both ends in Range are equivalent to nil and RangeExtd::Infinity
  #
  # Note that boundaries are not taken into account in this routine.
  # If, for example, {#exclude_end?} contradict, regardless of the returne
  # value of this routine, it should not be "equal".  The caller must handle it.
  #
  # @param other [Range, RangeExtd] Other object to compare with
  # @option method [Symbol] One of nil, +:eql?+, and +==+. If nil, method is irrelevant.
  def _both_eqleql_nil?(other, method=nil)
        # Neither self nor r is guaranteed to be RangeExtd::NONE
    is_self_begin_inf  = (self.begin.nil?  || RangeExtd::Infinity::NEGATIVE == self.begin)
    is_other_begin_inf = (other.begin.nil? || RangeExtd::Infinity::NEGATIVE == other.begin)
    is_self_end_inf    = (self.end.nil?    || RangeExtd::Infinity::POSITIVE == self.end)
    is_other_end_inf   = (other.end.nil?   || RangeExtd::Infinity::POSITIVE == other.end)

    method_ok = (method.nil? || (method == :==))
    method_ok && is_self_begin_inf && is_other_begin_inf && is_self_end_inf && is_other_end_inf
  end
  private :_both_eqleql_nil?
end	# class Range


# Constant-form of {#RangeExtd}.
#
# +RangeExtd()+ is equivalent to {#RangeExtd.new}().
#
# @return [RangeExtd]
def RangeExtd(*rest, **hs, &b)
  RangeExtd.new(*rest, **hs, &b)
end

