# -*- encoding: utf-8 -*-

## Load required files.
err1st = nil
req_files = %w(lib/range_extd/infinity/infinity)
req_files.each do |req_file|
  while ! req_file.empty?
    begin
      require req_file 
    rescue LoadError => errLoad
      err1st = errLoad if err1st.nil?
      if %r@/@ =~ req_file
        if req_file.sub!(%r@[^/]*/@, '').nil?	# Will search for the next directory down.
          raise
        end
      else
        req_file = ''
        break
      end
    else
      break
    end
  end
  if req_file.empty?
    raise err1st
  end
end	# req_files.each do |req_file|

########################################
# Initial set up of 2 constants in RangeExtd.
########################################

class RangeExtd < Range
  ## Temporary initialize() just to define the two constants.
  def initialize(rangepart, ex_begin, ex_end)
    @rangepart = rangepart
    @exclude_begin = ex_begin
    @exclude_end   = ex_end
  end

  # Two constants
  NONE = RangeExtd.new(nil...nil, true, true)	# In Ruby1.8, this causes  ArgumentError: bad value for range (because (nil..nil) is unaccepted).
  ALL  = RangeExtd.new(Infinity::NEGATIVE..Infinity::POSITIVE, false, false)

  #NONE.freeze
  #ALL.freeze
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
#  2. allows open-ended range (to the infinity),
#  3. defines NONE and ALL constants,
#  4. the first self-consistent logical structure,
#  5. complete backward compatibility within the built-in Range.
#
# The instance of this class is immutable, that is, you can not
# alter the element once an instance is generated.
#
# What is valid is checked with the class method {RangeExtd.valid?}.
# See the document of that method for the definition.
#
# To express open-ended ranges is simple; you just use either of
# the two (negative and positive, or former and later) constants
# in RangeExtd::Infinity class.  See the document for detail.
#
# @example An instance of a range of 5 to 8 with both ends being exclusive is created as
#   r = RangeExtd(5...8, true) 
#   r.exclude_begin?  # => true 
#
class RangeExtd < Range

  @@middle_strings = []

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
  #   @param obj_begin [Object] Any object that is {Comparable} with end
  #   @param obj_end [Object] Any object that is Comparable with begin
  #   @param exclude_begin [Boolean] If specified, this has the lower priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the lower priority, or false in default.
  #   @option opts [Boolean] :exclude_begin If specified, this has the higher priority, or false in default.
  #   @option opts [Boolean] :exclude_end If specified, this has the higher priority, or false in default.
  #
  # @overload new(obj_begin, string_form, obj_end, [exclude_begin=false, [exclude_end=false]], opts)
  #   @param obj_begin [Object] Any object that is {Comparable} with end
  #   @param string_form [Object] String form (without pre/postfix) of range expression set by {RangeExtd.middle_strings=}()
  #   @param obj_end [Object] Any object that is Comparable with begin
  #   @param exclude_begin [Boolean] If specified, this has the lower priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the lower priority, or false in default.
  #   @option opts [Boolean] :exclude_begin If specified, this has the higher priority, or false in default.
  #   @option opts [Boolean] :exclude_end If specified, this has the higher priority, or false in default.
  #
  # Note if you use the third form with "string_form" with the user-defined string
  # (via {RangeExtd.middle_strings=}()), make 100 per cent sure
  # of what you are doing.  If the string is ambiguous, the result may differ
  # from what you thought you would get!  See {RangeExtd.middle_strings=}() for detail.
  #
  # @raise [ArgumentError] particularly if the range to be created is not {#valid?}.
  def initialize(*inar, **hsopt)	# **k expression from Ruby 1.9?

    arout = RangeExtd.class_eval{ _get_init_args(*inar, hsopt) }	# class_eval from Ruby 1.8.7 (?)

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
      raise ArgumentError, "the argument can not consist of a RangeExtd instance."
    end

    @exclude_begin = arout.pop
    @exclude_end   = arout[-1]
    @rangepart = Range.new(*arout)

  end	# def initialize(*inar)


  # true if self is identical to {RangeExtd::NONE}.
  # This is different from {#==} method!
  # @example 
  #    RangeExtd(0,0,false,false) == RangeExtd::NONE  # => true
  #    RangeExtd(0,0,false,false).empty?    # => true
  #    RangeExtd(0,0,false,false).is_none?  # => false
  #    RangeExtd::NONE.is_none?     # => true
  def is_none?
    self.begin.nil? && self.end.nil? && @exclude_begin && @exclude_end	# Direct comparison with object_id should be OK?
  end

  # true if self is identical to {RangeExtd::ALL} ({#==} does not mean it at all!)
  # @example
  #    (RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE).is_all?  # => false
  def is_all?
    self.begin.object_id == Infinity::NEGATIVE.object_id && self.end.object_id == Infinity::POSITIVE.object_id && !@exclude_begin && !@exclude_end	# Direct comparison with object_id should not work for this one!! (because users can create an identical one.)
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
    re_equal_core(r, :==)
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
    re_equal_core(r, :eql?)
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
  # algorithm of built-in {Range#include?} is different and cheating!
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
  # as Ruby's {Range} knows the algorithm of {String#succ} and {String#<=>}
  # and specifically checks with it, before using {Enumerable#include?}.
  # {https://github.com/ruby/ruby/blob/trunk/range.c}
  #
  # Therefore, even if you change the definition of {String#succ}
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
  # the resutl of {Range#===} will unchange;
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
  # In short, bsearch works only with Integer and/or Float (as in Ruby 2.1).
  # If either of begin and end is an Float, the search is conducted in Float and the returned value will be Float, unless nil.
  # If Float, it searches on the binary plane.
  # If Integer, the search is conducted on the descrete Integer points only,
  # and no search will be made in between the adjascent integers.
  #
  # Given that, {RangeExtd#bsearch} follows basically the same, even when exclude_begin? is true.
  # If either end is Float, it searches between begin*(1+Float::EPSILON) and end.
  # If both are Integer, it searches from begin+1.
  # When {#exclude_begin?} is false, {RangeExtd#bsearch} is identical to {Range#bsearch}.
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


  # See {#include?} or {#===}, and {Range#cover?}
  def cover?(i)
    # ("a".."z").cover?("cc")	# => true
    # (?B..?z).cover?('dd')	# => true  (though 'dd'.succ would never reach ?z)

    return false if is_none?	# No need of null?(), supposedly!

    if @exclude_begin
      if self.begin == i
        false
      else
        @rangepart.send(__method__, i)
      end
    else
      @rangepart.send(__method__, i)
    end
  end	# def cover?(i)


  # @raise [TypeError] If {#exclude_begin?} is true, and {#begin}() or {#rangepart} does not have a method of [#succ], then even if no block is given, this method raises TypeError straightaway.
  # @return [RangeExtd] self
  # @return [Enumerator] if block is not given.
  #
  def each(*rest, &bloc)
    # (1...3.5).each{|i|print i}	# => '123' to STDOUT
    # (1.3...3.5).each	# => #<Enumerator: 1.3...3.5:each>
    # (1.3...3.5).each{|i|print i}	# => TypeError: can't iterate from Float
    # Note: If the block is not given and if @exclude_begin is true, the self in the returned Enumerator is not the same as self here.
    if @exclude_begin	# including RangeExtd::NONE
      if defined? self.begin.succ
        ret = Range.new(self.begin.succ,self.end,exclude_end?).send(__method__, *rest, &bloc)
        if block_given?
          self
        else
          ret
        end
      elsif is_none?
        raise TypeError, "can't iterate for NONE range"
      else
        raise TypeError, "can't iterate from "+self.begin.class.name
      end
    else
      @rangepart.send(__method__, *rest, &bloc)
    end
  end


  # Like {Range#last}, if no argument is given, it behaves like {#begin}(), that is, it returns the initial value, regardless of {#exclude_begin?}.
  # However, if an argument is given (nb., acceptable since Ruby 1.9) when {#exclude_begin?} is true, it returns the array that starts from {#begin}().succ().
  # @raise [TypeError] if the argument (Numeric) is given and if {#exclude_begin?} is true, yet if {#begin}().succ is not defined, or yet if {#is_none?}
  # @param rest [Integer] Optional.  Must be non-negative.  Consult {Range#first} for detail.
  # @return [Object] if no argument is given, equivalent to {#end}.
  # @return [Array] if an argument is given.
  def first(*rest)
    # (1...3.1).last	# => 3.1
    # (1...3.1).last(1)	# => [3]
    if ! @exclude_begin	# hence, not NONE.
      @rangepart.first(*rest)
    else
      case rest.size
      when 0
        self.begin
      when 1
        if (RUBY_VERSION < "1.9.1") && (1 == rest[0])	# Range#first() does not accept an argument in Ruby 1.8.
          raise ArgumentError, "wrong number of arguments (#{rest.size} for 0) (Use Ruby 1.9.2 or later)."
        end

        ## Check the argument.
        Array.new[ rest[0] ]	# Check Type of rest[0] (if invalid, it should raise TypeError)

        begin
          if rest[0] < 0
            raise ArgumentError, "negative array size (or size too big)"
          end
        rescue NoMethodError
          # Should not happen, but just to play safe.
        end

        ## Main
        if ! defined? self.begin.succ
          raise TypeError, "can't iterate from "+self.begin.class.name
        end

        Range.new(self.begin.succ, self.end, exclude_end?).send(__method__, *rest)
      else
        raise ArgumentError, "wrong number of arguments (#{rest.size} for 0..1)"
      end
    end		# if ! @exclude_begin
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


  # See {Range#last}.
  # If either (let alone both) side of the edge is Infinity, you can not give
  # an argument in practice, the number of the members of the returned array.
  #
  # @raise [TypeError] If self.begin.succ is not defined, or if either side is Infinity.
  # @return [Object] if no argument is given, equivalent to {#end}.
  # @return [Array] if an argument is given.
  def last(*rest)
    return nil if null?
    nSize = rest.size
    case nSize
    when 0
      self.end
    when 1
        if (RUBY_VERSION < "1.9.1") && (1 == rest[0])	# Range#first() does not accept an argument in Ruby 1.8.
          raise ArgumentError, "wrong number of arguments (#{rest.size} for 0) (Use Ruby 1.9.2 or later)."
        end

      if  defined?(self.begin.infinity?) && self.begin.infinity? || self.begin == -Infinity::FLOAT_INFINITY
        raise TypeError, "can't iterate from "+self.begin.to_s
      elsif defined?(self.end.infinity?) && self.end.infinity?   || self.end   ==  Infinity::FLOAT_INFINITY
        raise TypeError, "can't get elements to "+self.end.to_s
      elsif ! defined? self.begin.succ
        raise TypeError, "can't iterate from "+self.begin.class.name
      else
        @rangepart.send(__method__, *rest)
      end
    else
      raise ArgumentError, "wrong number of arguments (#{rest.size} for 0..1)"
    end
  end	# def last(*rest)


  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def min(*rest, &bloc)
    re_min_max_core(__method__, *rest, &bloc)
  end

  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def min_by(*rest, &bloc)
    re_min_max_core(__method__, *rest, &bloc)
  end


  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def minmax(*rest, &bloc)
    # (0...3.5).minmax	# => [0, 3]
    # (1.3...5).minmax	# => TypeError: can't iterate from Float
    # Note that max() for the same Range raises an exception.
    # In that sense, it is inconsistent!
    re_min_max_core(__method__, *rest, &bloc)
  end

  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def minmax_by(*rest, &bloc)
    # (0...3.5).minmax	# => [0, 3]
    # Note that max() for the same Range raises an exception.
    # In that sense, it is inconsistent!
    re_min_max_core(__method__, *rest, &bloc)
  end


  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def max(*rest, &bloc)
    re_min_max_core(__method__, *rest, &bloc)
  end

  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  def max_by(*rest, &bloc)
    re_min_max_core(__method__, *rest, &bloc)
  end


  # Implementation of {Range#size} to this class.
  #
  # It is essentially the same, but the behaviour when {#exclude_begin?} is true
  # may not always be natural.
  # See {#first} for the definition when {#exclude_begin?} is true.
  #
  # {Range#size} only works for Numeric ranges.
  # And in {Range#size}, the value is calculated when the initial value is
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
  # @see http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/49797 [ruby-list:49797] from matz for how {Range#size} behaves (in Japanese).
  #
  # @return [Integer]  0 if {RangeExtd::NONE}
  # @return [Float]  Float::INFINITY if either (or both) the end is infinity, regardless of the class of the elements. 
  # @return [nil] if the range is non-Numeric.
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

    if is_none?	# No need of null?(), supposedly!
      return 0

    ### (Infinity..Infinity) => 0  (as in Ruby 2.1)
    # elsif self.begin().infinity? || self.end().infinity?
    #   return Infinity::FLOAT_INFINITY

    # Checking Infinity.
    # Note (Infinity..Infinity) => 0  (Range as in Ruby 2.1)
    # however, 
    elsif (defined?(self.begin.infinity?) && self.begin.infinity? || self.begin == -Infinity::FLOAT_INFINITY) ||
          (defined?(self.end.infinity?)   && self.end.infinity?   || self.end == Infinity::FLOAT_INFINITY)
      if self.begin == self.end
        return 0
      else
        return Infinity::FLOAT_INFINITY
      end

    elsif @exclude_begin

      begin
        _dummy = 1.0 + self.begin()	# _dummy to suppress warning: possibly useless use of + in void context

        # Numeric
        if defined? (self.begin().succ)
          Range.new(self.begin().succ, self.end, exclude_end?).send(__method__, *rest)
        else
          size_no_exclude = Range.new(self.begin, self.end).send(__method__, *rest)	# exclude_end? == true, ie., Range with both ends inclusinve.
          diff = self.end - self.begin
          if diff.to_i == diff		# Integer difference
            return size_no_exclude - 1	# At least exclude_begin?==true (so exclude_end? does not matter)
          else
            return size_no_exclude
          end
        end
      rescue TypeError
        # Non-Numeric
        if defined? self.begin().succ
          Range.new(self.begin().succ, self.end, exclude_end?).send(__method__, *rest)	# => nil in Ruby 2.1
        else
          nil	# See the line above.
          # raise TypeError, "can't iterate from "+self.begin.class.name
        end

      end

    else
      @rangepart.send(__method__, *rest)
    end
  end	# def size


  # See {#each}.
  # @raise [TypeError] If {#exclude_begin?} is true, and {#begin}() does not have the method [#succ], then even if no block is given, this method raises TypeError straightaway.
  # @return [RangeExtd] self
  # @return [Enumerator] if block is not given.
  #
  def step(*rest, &bloc)
    # (1...3.5).each{|i|print i}	# => '123' to STDOUT
    # (1.3...3.5).each	# => #<Enumerator: 1.3...3.5:each>
    # (1.3...3.5).each{|i|print i}	# => TypeError: can't iterate from Float
    # Note: If the block is not given and if exclude_begin?() is true, the self in the returned Enumerator is not the same as self here.

    if @exclude_begin	# including RangeExtd::NONE
      if defined? self.begin.succ
        ret = Range.new(self.begin.succ,self.end,exclude_end?).send(__method__, *rest, &bloc)
        if block_given?
          self
        else
          ret
        end
      elsif is_none?	# No need of null?(), supposedly!
        raise TypeError, "can't iterate for NONE range"
      else
        raise TypeError, "can't iterate from "+self.begin.class.name
      end
    else
      @rangepart.send(__method__, *rest, &bloc)
    end
  end


  ##################################################
  # Class methods
  ##################################################

  # Private class method to evaluate the arguments.
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
      # arRet = [inar[0].begin, inar[0].end, exclude_end, exclude_begin]
      # @rangepart = Range.new(inar[0].begin, inar[0].end, exclude_end)

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
      if inar.size > 2 && defined?(inar[1].=~)
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
          if $1 == @@middle_strings[1]
            exclude_begin = false
          else
            exclude_begin = true
          end
          if $2 == @@middle_strings[4]
            exclude_end   = true
          else
            exclude_end   = false
          end
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

      # arRet = [inar[0], inar[1], exclude_end, exclude_begin]
      # @rangepart = Range.new(inar[0], inar[1], exclude_end)

    else
      raise	# (for coding safety)
    end		# case hsFlag[:prm1st]

    if hsopt.has_key?(:exclude_begin)
      exclude_begin = (hsopt[:exclude_begin] && true)
    end
    if hsopt.has_key?(:exclude_end)
      exclude_end   = (hsopt[:exclude_end] && true)
    end

    beginend + [exclude_end, exclude_begin]

  end	# def self._get_init_args(*inar)

  private_class_method :_get_init_args	# From Ruby 1.8.7 (?)


  # Returns true if the range to be constructed (or given) is valid,
  # as a range, accepted in {RangeExtd}.
  #
  # This routine is also impremented as a method in {Range},
  # and accordingly its sub-classes.
  #
  # This routine is called from {RangeExtd.new}, hence
  # for any instance of {RangeExtd} class, its {#valid?} returns true.
  #
  # What is valid is defined as follows:
  #
  # 1. Both {#begin} and {#end} elements must be Comparable to each other,
  #    and the comparison results must be consistent betwen the two.
  #    The sole exception is {RangeExtd::NONE}, which is valid.
  #    For example, (nil..nil) is NOT valid (nb., it raised Exception in Ruby 1.8).
  # 2. {#begin} must be smaller than or equal to {#end},
  #    that is, ({#begin} <=> {#end}) must be either -1 or 0.
  # 3. If {#begin} is equal to {#end}, namely, ({#begin} <=> {#end}) == 0,
  #    the exclude status of the both ends must agree.
  #    That is, if the {#begin} is excluded, {#end} must be also excluded,
  #    and vice versa.
  #    For example, (1...1) is NOT valid for that reason,
  #    because any built-in Range object has the exclude status
  #    of false (namely, inclusive) for {#begin}.
  #
  # Note the last example may change in the future release.
  #
  # Note ([2]..[5]) is NOT valid, because Array does not include Comparable
  # for some reason, as of Ruby 2.1.1, even though it has the redefined
  # and working [#<=>].  You can make those valid, by including Comparable
  # in Array class, should you wish.
  #
  # @example
  #
  #    RangeExtd.valid?(nil..nil)     # => false
  #    RangeExtd.valid?(nil...nil)    # => false
  #    RangeExtd.valid?(0..0)         # => true
  #    RangeExtd.valid?(0...0)        # => false
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
  # @overload new(range, [exclude_begin=false, [exclude_end=false]])
  #   @param [Object] range Instance of Range or its subclasses, including RangeExtd
  #   @param exclude_begin [Boolean] If specified, this has the higher priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the higher priority, or false in default.
  #
  # @overload new(obj_begin, obj_end, [exclude_begin=false, [exclude_end=false]])
  #   @param obj_begin [Object] Any object that is {Comparable} with end
  #   @param obj_end [Object] Any object that is Comparable with begin
  #   @param exclude_begin [Boolean] If specified, this has the lower priority, or false in default.
  #   @param exclude_end [Boolean] If specified, this has the lower priority, or false in default.
  #
  def self.valid?(*inar)
    (vbeg, vend, exc_beg, exc_end) = _get_init_args(*inar)

    if defined?(inar[0].is_none?) && inar[0].is_none? && exc_beg && exc_end
      return true
    end
      
    begin
      t = (vbeg <=> vend)
      begin
        return false if t != -1*(vend <=> vbeg)	# false if not commutative, or possibly exception (such as -1*nil).
      rescue NoMethodError, TypeError
        if (Float === vend && defined?(vbeg.infinity?) && vbeg.infinity?) ||
           (Float === vbeg && defined?(vend.infinity?) && vend.infinity?)
          warn "Float::INFINITY is not comparable with other Infinity."
        end
        return false	# return
      end
    rescue # NoMethodError
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
        if (Float === vend && defined?(vbeg.infinity?) && vbeg.infinity?) ||
           (Float === vbeg && defined?(vend.infinity?) && vend.infinity?)
          warn "Float::INFINITY is not comparable with other Infinity."
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
  def re_equal_core(r, method)
    if defined? r.empty?
      is_r_empty = r.empty?
    else
      return false	# Not Range family.
    end
    if ! defined? r.exclude_end?
      false	# Not Range family.
    elsif is_none? && is_r_empty	# RangeExtd::NONE
      true
    elsif empty? && defined?(r.is_none?) && r.is_none?	# r is RangeExtd::NONE
      true
    elsif empty?   && is_r_empty
      if method == :eql?
        # More strict
        if self.begin().class == r.begin().class
          true	#     (1<...1).eql? (2<...2)	# => true  (Fixnum <-> Fixnum) Yes!
        else
          false	# (1.0<...1.0).eql? (2<...2)	# => false (Float  <-> Fixnum) No!
        end
      else
        (self.begin.class.ancestors - self.begin.class.included_modules - [Object, BasicObject]).each do |ec|
          if ec === r.begin
            return true	# (1.0<...1.0) == (2<...2)	# (Float<Numeric <-> Fixnum<Numeric) Yes!
          end
        end
        false		#    (?a...?a) != (2<...2)	# (String <-> Numeric) No!
      end

    elsif defined? r.exclude_begin?
      (self.exclude_begin? ^! r.exclude_begin?) &&
        (self.exclude_end? ^! r.exclude_end?) &&
        (self.begin.send(method, r.begin)) &&
        (self.end.send(  method, r.end))
        # (self.begin == r.begin) &&
        # (self.end == r.end)
    else 
      # r is Range
      if self.exclude_begin?
        false
      else
        @rangepart.send(method, r)	# Comparison as two Range-s.
      end
    end
  end	# def re_equal_core(r, method)

  # Core routine for {#min}, {#max}, {#minmax} etc.
  # @param method [Symbol] of the method name.
  # @param rest [Object]
  def re_min_max_core(method, *rest, &bloc)
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
  end	# def re_min_max_core(method, *rest, &bloc)

end	# class RangeExtd < Range


#= Class Range
#
#== Summary
#
# Modifies {#==}, {#eql?} and add methods of
# {#valid?}, {#empty?}, {#null?}, {#is_none?} and {#is_all?}.
#
class Range

  alias :equal_prerangeextd? :==  if ! self.method_defined?(:equal_prerangeextd?)	# No overwriting.

  # It is extended to handle {RangeExtd} objects.
  # For each element, that is, {#begin} and {#end},
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
    equal_core(r, :==, :equal_prerangeextd?)
  end


  alias :eql_prerangeextd? :eql?  if ! self.method_defined?(:eql_prerangeextd?)	# No overwriting.

  # Same as {#==}, but the comparison is made with eql?() method.
  def eql?(r)
    equal_core(r, :eql?, :eql_prerangeextd?)
  end


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
  #  because {RangeExtd.new} checks the validity.
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
  # 2. if the range id discrete, that is, {#begin} has
  #    [#succ] method, there must be no member within the range: 
  #    {#to_a}.empty? => true
  # 3. if the range is continuous, that is, {#begin} does not have
  #    [#succ] method, {#begin} and {#end} must be equal
  #    (({#begin} <=> {#end}) => 0) and both the boundaries must
  #    be excluded: ({#exclude_begin?} && {#exclude_end?}) => true.
  #    Note that ranges with equal {#begin} and {#end} with
  #    inconsistent two exclude status are not valid, and the built-in
  #    Range always has the {#begin}-exclude status of false.
  #
  # In these conditions, none of Range instance would return true in {#empty?}.
  #
  # @example
  #   (nil..nil).empty?  # => nil
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
    elsif defined?(self.is_none?) && self.is_none?
      return true
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
      if defined?(self.boundary) && self.boundary.nil?	# for RangeOpen
        # RangeExtd::NONE or RangeExtd::All
        if self.exclude_end?
          true	# RangeOpen::NONE
        else
          false	# RangeOpen::ALL
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
  # See {#empty?} and {#valid?}.
  def null?
    (! valid?) || empty?
  end

  # @return [FalseClass]
  def is_none?
    false
  end

  # @return [FalseClass]
  def is_all?
    false
  end

  ############## pravate methods of Range ##############

  private

  # True if obj is Comparable.
  def is_comparable?(obj)
    if defined?(obj.<=)	# Comparable?
      true
    else
      false
    end
  end

  # @param r [Object] to compare.
  # @param method [Symbol] of the method name.
  # @param method_pre [Symbol] of the backed-up original method name.
  def equal_core(r, method, method_pre)
    if (! defined? r.exclude_end?) || (! defined? r.is_none?) || (! defined? r.empty?)
      false	# Not Range family.
    # elsif empty? && defined?(r.is_none?) && r.is_none?	# r is RangeExtd::NONE
    #   true
    # elsif empty? && r.empty?
    #   # None of built-in Range class object can be #empty?==true - This is for sub-class.
    # 
    elsif defined? r.exclude_begin?
      # Either RangeExtd or RangeOpen object.
      if r.exclude_begin?
        false	# self(Range) has always the inclusive begin.
      else
        # It could do with a single line,
        #    self.begin.send(method_pre, r)
        # if this was for RangeExtd===r, but not for RangeOpen.
        if (self.exclude_end? ^ r.exclude_end?)
          false
        elsif (self.begin.send(method, r.begin) && self.end.send(method, r.end))
          true
        else
          false
        end
      end
    else
      self.send(method_pre, r)	# r is Range.
    end
  end	# def equal_core(r, method, method_pre)

end	# class Range


# Constant-form of {#RangeExtd}.
# #RangeExtd(*) is equivalent to {#RangeExtd.new}.
#
def RangeExtd(*rest, &b)
  RangeExtd.new(*rest, &b)
end

