# -*- encoding: utf-8 -*-

if ! defined?(Rational)
  require 'rational'	# For Ruby 1.8
end

## NOTE: Write nothing for the class description of RangeExtd, because it would have a higher priority for yard!


class RangeExtd < Range
  # Constant to represent no {RangeExtd}. Note that +(3...3).valid?+, for example, is false under this scheme, and it should be represented with this constant.
  NONE = :Abstract

  # Constant to represent a general {RangeExtd} that include everything (negative to positive infinities). This is basically a generalized version of range of +(-Float::INFINITY..Float::INFINITY)+ to any (comparable) Class objects.
  ALL = :Abstract

  #
  # =Class RangeExtd::Infinity
  #
  # Authors:: Masa Sakano
  # License:: MIT
  #
  # ==Summary
  #
  # Class to hold just two constants: 
  # * RangeExtd::Infinity::NEGATIVE
  # * RangeExtd::Infinity::POSITIVE
  #
  # and two more:
  #
  # * CLASSES_ACCEPTABLE (see below)
  # * FLOAT_INFINITY  (OBSOLETE; workaround for Ruby 1.8 to represent Float::INFINITY)
  #
  # There  no other object in this class (you can not create a new one).
  #
  # This class includes Comparable module.
  #
  # ==Description
  #
  # Both the two constant are abstract values which are always smaller/larger,
  # respectively, than any other Comparable objects (1 or -1 by i{#<=>}(obj))
  # except for infinities with the same polarity, that is, positive or negative,
  # in which case 0 is returned.
  # See the document of the method {#==} for the definition of "infinity".
  #
  # +Infinity#succ+ used to be defined up to {RangeExtd} Ver.1 but is removed in Ver.2+.
  #
  # There is a note of caution.
  # The method {#<=>} is defined in this class as mentioned above.
  # However any operator is, by Ruby's definition, not commutative,
  # unless both the classes define so.
  #
  # There are only three built-in classes that are Comparable: String, Time and Numeric
  # (except for Complex).
  # Note Date and DateTime objects are so, too, however practically
  # they need "require", hence are (and must be) treated, the same as any other classes.
  # For String and Time class objects, the [#<=>] operator work as expected
  # in the commutative way.
  #    ?z <=> RangeExtd::Infinity::POSITIVE    # => nil
  #    RangeExtd::Infinity::POSITIVE <=> ?z    # => 1.
  #
  # For Numeric, it does not.
  #    50 <=> RangeExtd::Infinity::POSITIVE    # => nil
  #    RangeExtd::Infinity::POSITIVE <=> 50    # => 1.
  #
  # For that reason, for example,
  #   ( 50 .. RangeExtd::Infinity::POSITIVE)
  # raises an exception, because the Numeric instance 50 does not
  # know how to compare itself with a RangeExtd::Infinity instance,
  # and Range class does not allow such a case.
  #
  # For Numeric, this is deliberately so.
  # Please use +Float::INFINITY+ instead in principle;
  # it will be a lot faster in run-time, though it is
  # perfectly possible for you to implement the feature
  # in Numeric sub-classes, if need be.
  #
  # Any other Comparable classes are defined by users by definition,
  # whether you or authors of libraries.
  # The comparison with {RangeExtd::Infinity} instances are
  # implemented in {Object#<=>} in this library.  Hence, as long as
  # the method [#<=>] in the classes is written sensibly, that is, if it
  # respects the method of the super-class when it does not know
  # how to deal with an unknown object, there is no need for
  # modification.  Any object in your class (say, YourComparable) 
  # is immediately comparable with the {RangeExtd::Infinity} instances,
  #    YourComparable.new <=> RangeExtd::Infinity::POSITIVE    # => -1
  #    RangeExtd::Infinity::POSITIVE <=> YourComparable.new    # => 1
  # except for the infinity inscances in YourComparable (see {#==}).
  #
  # See the document in {Object#<=>} in this code/package for detail.
  #
  # However, some existing Comparable classes, perhaps written by some
  # one else may not be so polite, and has disabled comparison
  # with any object but those intended.  Unlucky you!
  # For example, the classes like Date and DateTime are one of them.
  #
  # For that sort of circumstances,
  # the class method {RangeExtd::Infinity.overwrite_compare} provides
  # a convenient way to overcome this problem to make
  # the operator [#<=>] commutative for a given Comparable class.
  #
  # Note {RangeExtd::Infinity.overwrite_compare} does nothing for the classes
  # registered in the Class constant Array {RangeExtd::Infinity::CLASSES_ACCEPTABLE}.
  # So, if you want to avoid such modification of the method [#<=>], perhaps
  # by some other end users, you can register the class in that array.
  #
  # Only the instance methods defined in this class are
  # {#===}, {#==}, {#<=>}, {#to_s}, {#inspect},
  # {#infinity?}, {#positive?} and {#negative?}, and in addition, since Version 1.1,
  # two unary operators {#@+} and {#@-} to unchange/swap the parity are defined
  # ({#<} and {#>} are modified, too, to deal with Integer and Float;
  # I do not know whether the default behaviour of these classes have changed
  # in the recent versions of Ruby, hence resulting in the neccesity of this change).
  #
  # === Comparison operators
  #
  # {RangeExtd::Infinity::POSITIVE} and InfN {RangeExtd::Infinity::NEGATIVE}
  # are always comparable with any comparable objects except for
  # Float::INFINITY, in which case
  #
  #   (RangeExtd::Infinity::POSITIVE <=> Float::INFINITY)  # => nil
  #   (RangeExtd::Infinity::POSITIVE <   Float::INFINITY)  # => ArgumentError
  #   (RangeExtd::Infinity::POSITIVE >   Float::INFINITY)  # => ArgumentError
  #   (RangeExtd::Infinity::POSITIVE ==  Float::INFINITY)  # => false
  #
  # which is what happens for the comparison operators for Float::INFINITY.
  #
  # Basically, the concept of {RangeExtd::Infinity::POSITIVE} is a generalised
  # concept of Float::INFINITY.  Therefore they are really not *equal*.
  # On the other hand, {RangeExtd::Infinity::POSITIVE} is *greater* than
  # any normal comparable objects (except those that are *infinite*).
  # Therefore, all the following are true ({Object#<=>} and some methods
  # in some classes are modified)
  #
  #   (5 < RangeExtd::Infinity::POSITIVE)
  #   (5 > RangeExtd::Infinity::NEGATIVE)
  #
  #   ("a" < RangeExtd::Infinity::POSITIVE)
  #   ("a" > RangeExtd::Infinity::NEGATIVE)
  #
  # whereas
  #
  #   (RangeExtd::Infinity::POSITIVE < Object.new)  # => ArgumentError
  #
  # raises ArgumentError.
  #
  class Infinity
  
    include Comparable

    # Obsolete Constant FLOAT_INFINITY (for the sake of Ruby 1.8 or earlier).
    # Please do not use it - it will be removed some time in the future.
    # n.b., Module#private_constant is introduced in Ruby 1.9.3.
    begin
      FLOAT_INFINITY = Float::INFINITY 
    rescue	# Ruby 1.8 or earlier.
      FLOAT_INFINITY = 1/0.0
    end

    # Classes that accept to be compared with Infinity instances.
    CLASSES_ACCEPTABLE = [self, Float, Integer, Rational, Numeric, String]  # Fixnum, Bignum deprecated now.
    # CLASSES_ACCEPTABLE = [self, Float, Fixnum, Bignum, Rational, Numeric, String]	# , BigFloat
    CLASSES_ACCEPTABLE.push BigFloat if defined? BigFloat

    # Unary Operator: Plus
    def +@
      self
    end

    # Unary Operator: Minus
    def -@
      positive? ? NEGATIVE : POSITIVE
    end

    # returns always true.
    #
    # @see Infinity.infinity?
    def infinity?
      true
    end
    #alias_method :infinite?, :infinity? if !self.method_defined? :infinite?  # Common with Float::INFINITY
    ## If the alias for :infinite? is defined as above, the following would raise
    #    NoMethodError: undefined method `>' for true:TrueClass
    #  in the operation
    #    Float::INFINITY <=> RangeExtd::Infinity::POSITIVE
    #
  
    # true if self is a positive infinity
    def positive?
      @positive 
    end
  
    # true if self is a negative infinity
    def negative?
      !@positive 
    end

    alias_method :cmp_before_rangeextd_infinity?, :==  if ! self.method_defined?(:cmp_before_rangeextd_infinity?)	# No overwriting.

    # Always -1 or 1 except for itself and the corresponding infinities (== 0).  See {#==}.
    # Or, nil (as defined by Object), if the argument is not Comparable, such as, nil and IO.
    #
    # @return [Integer, nil]
    def <=>(c)
      if c.nil? || !c.respond_to?(:<=) # Not Comparable?
        nil
      elsif c == Float::INFINITY
        nil  # Special case.
      else
        (self == c) ? 0 : (@positive ? 1 : -1)
      end
    end

    alias_method :greater_than_before_rangeextd_infinity?, :>  if ! self.method_defined?(:greater_than_before_rangeextd_infinity?)	# No overwriting.
    # Special case for Float::INFINITY
    #
    #   (Float::INFINITY > RangeExtd::Infinity::POSITIVE)
    # raises ArgumentError and so does this method.
    def >(c)
      ((c.abs rescue c) == Float::INFINITY) ? raise(ArgumentError, "RangeExtd::Infinity object not comparable with '#{__method__}' with Float::INFINITY") : greater_than_before_rangeextd_infinity?(c)
    end

    alias_method :less_than_before_rangeextd_infinity?, :<  if ! self.method_defined?(:less_than_before_rangeextd_infinity?)	# No overwriting.
    # Special case for Float::INFINITY
    #
    #   (Float::INFINITY > RangeExtd::Infinity::POSITIVE)
    # raises ArgumentError and so does this method.
    def <(c)
      ((c.abs rescue c) == Float::INFINITY) ? raise(ArgumentError, "RangeExtd::Infinity object not comparable with '#{__method__}' with Float::INFINITY") : less_than_before_rangeextd_infinity?(c)
    end

    # Always false except for itself and the corresponding +Float::INFINITY+
    # and those that have methods of {#infinity?} and {#positive?}
    # with the corresponding true/false values, in which case this returns true.
    def ==(c)
      if (Infinity === c)
        (@positive ^! c.positive?)	# It should be OK to compare object_id?
      #elsif c ==  FLOAT_INFINITY &&  @positive
      #  true
      #elsif c == -FLOAT_INFINITY && !@positive
      #  true
      elsif defined?(c.infinity?) && defined?(c.positive?)
        (c.infinity? && (@positive ^! c.positive?))
      else
        false
      end
    end

    # Equivalent to {#==}
    def ===(c)
      self == c
    end
  
    # This used to be defined till RangeExtd Ver.1
    ## @return [Infinity] self
    #def succ
    #  self
    #end
  
    # @return [String]
    def inspect
      if @positive 
        "INFINITY"
      else
        "-INFINITY"
      end
    end
  
    alias_method :to_s, :inspect
  

  # Overwrite [#<=>] method of the given class, if necessary,
  # to make its instances be comparable with RangeExtd::Infinity objects (constants).
  # For example,
  #   RangeExtd::Infinity::NEGATIVE.<=>(any_comparable)
  # always gives back -1 (except for same infinities).  However the other way around,
  #   SomeClass.new.<=>(RangeExtd::Infinity::NEGATIVE)
  # usually returns nil, which is not handy.
  # Therefore, this function (Class method) provides a convenient
  # way to overcome it, that is, if the given class
  # (or the class of the given object) is Comparable,
  # its [#<=>] method is modified (and true is returned),
  # unless it has been already done so, or some classes as listed below,
  # such as Numeric and String, in which case nil is returned.
  # If it is not Comparable, false is returned.
  # The judgement whether it is Comparable or not is based
  # whether the class has an instance method +ThatClass#<=+
  #
  # In processing, this method first looks up at an Array
  # {RangeExtd::Infinity::CLASSES_ACCEPTABLE},
  # and if the given class is registered in it,
  # it does nothing.  If not, and if all the othe conditions
  # are met, it overwrites its <=> method and register
  # the class in the array.
  #
  # @param obj [Object] Either Class or its object.
  # @return [Boolean, nil] (see the description).
  def self.overwrite_compare(obj)
    if defined? obj.instance_methods
      klass = obj
    else
      klass = obj.class

      begin
        _ = 1.0 + obj	# Use  "rescue ArgumentError"  if using "1.0<obj"
        return nil	# No change for Numeric
      rescue TypeError
      end
    end		# if defined? obj.instance_methods

    # [Numeric, Fixnum, Bignum, Float, Rational, String, Complex].each do |i|	# , BigFloat
    (self::CLASSES_ACCEPTABLE+[self]).each do |i|	# , BigFloat
      # The class itself (RangeExtd::Infinity) must be rejected!
      # Otherwise the rewrites itself, and may cause an infinite loop.
      # In fact it is pre-defined in RangeExtd::Infinity, so the above addition is a duplication - just to make sure.
      return nil if i == klass		# No change for Numeric etc
      # Built-in String, Numeric etc try to flip over "<=>" if it doesn't know the object!
    end
    self::CLASSES_ACCEPTABLE.push(klass)	# The class is registered, so it would not come here again for the class.

    a = klass.instance_methods
    if !a.include?( :<= )	# NOT Comparable
      return false
    elsif a.include?(:compare_before_infinity)
      return nil
    else
      # Overwrite the definition of "<=>" so that it is fliped over for Infinity.

      code = <<__EOF__
  alias_method :compare_before_infinity, :<=> if ! self.method_defined?(:compare_before_infinity)
  def <=>(c)
    if defined?(self.<=) && RangeExtd::Infinity === c
      if defined?(self.infinity?) && defined?(self.positive?)
        if (self.positive? ^! c.positive?)
          0
        elsif self.positive?
          1
        else
          -1
        end
      else
        if c.positive?
          -1
        else
          1
        end
      end
    else
      compare_before_infinity(c)
    end
  end
__EOF__
#<<__EOF__	# for Emacs hilit.

      klass.class_eval(code)

      true
    end
  end	# def self.overwrite_compare(obj)

  # True if obj is a kind of Infinity like this class (excluding +Float::INFINITY+)
  #
  # This is similar to the following but is in a duck-typing way:
  #
  #   RangeExtd::Infinity === obj
  #
  # Note that this returns false for Float::INFINITY.
  # If you want true for Float::INFINITY, use {RangeExtd::Infinity.infinite?} instead.
  #
  # @param obj [Object]
  def self.infinity?(obj)
    kl = obj.class
    kl.method_defined?(:infinity?) && kl.method_defined?(:positive?) && kl.method_defined?(:negative?)
  end

  # True if obj is either +Float::INFINITY+ or Infinity type.
  #
  # Note +Float#infinite?+ is defined - how to memorise this method name.
  #
  # @param obj [Object]
  def self.infinite?(obj)
    kl = obj.class
    (kl.method_defined?(:infinite?) && obj.infinite?) || (kl.method_defined?(:infinity?) && obj.infinity?)
  end

  ######################################
  # Special tricky routine below.  Do not even touch!
  ######################################

    private
  
    def initialize(t)
      @positive = (t && true)
    end
  
    #self.remove_const :NEGATIVE if defined? self::NEGATIVE  # tricky manoeuvre for documentation purposes... (see infinity.rb for the explanatory document)
    #self.remove_const :POSITIVE if defined? self::POSITIVE  # However, in this case, I have failed to include their descriptions in yard after many attempts, possibly because of "private"... (so these lines are commented out.)
    NEGATIVE = new(false)
    POSITIVE = new(true)

    #NEGATIVE.freeze
    #POSITIVE.freeze

  end	# class Infinity
  
  
  class Infinity
    # Disable new() so no other object will be created.
    private_class_method :new
  
    ######################################
    # Special tricky routine below.  Do not rouch!
    ######################################

    warn_level = $VERBOSE
    begin
      $VERBOSE = nil	# Suppress the warning in the following line.
      remove_method :initialize
    ensure
      $VERBOSE = warn_level
    end
    #undef_method :initialize

  end	# class Infinity
  
end	# class RangeExtd < Range


#
# = class Object
#
# Overwrite {Object#<=>}() so all its sub-classes can be
# aware of {RangeExtd::Infinity} objects (the two constants).
#
class Object
  alias_method :compare_obj_before_infinity, :<=>  if ! self.method_defined?(:compare_obj_before_infinity)	# No overwriting.

  # Overwrite {Object#<=>}().  Then, all its sub-classes can be
  # aware of RangeExtd::Infinity objects (the two constants).
  #
  # In this definition of {#<=>}, if self is Comparable
  # (by judging whether it has the method [#<=]),
  # it always returns, unless infinity? and positive? are set
  # accordingly, either -1 or 1, depending which of
  #   RangeExtd::Infinity::(NEGATIVE|POSITIVE)
  # is compared.  If self is not Comparable, the original [#<=>]
  # is called, which should return nil (unless both the object_id
  # agree, eg., nil and nil, in which case 0 is returned).
  #
  # If you define your own class, which is Comparable, you should
  # define the method "<=>" as follows, as in the standard practice
  # when you redefine a method that exists in a superclass;
  #
  # @example A method definition of user-defined Comparable class
  #    class MyComparableClass 
  #      include Comparable
  #      # alias :cmp_orig :<=> if !self.method_defined?(:cmp_orig)	# if you want
  #      def <=>(c)
  #        if c._is_what_i_expect?
  #          # Write your definition.
  #        else       # When self does not know what to do with c.
  #          super c  # to call Object#<=>
  #        end
  #      end
  #    end
  #
  def <=>(c)
    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_obj_before_infinity(c)
  end	# def <=>(c)
end	# class Object


#
# = class Numeric
#
# Modify {Numeric#>} and {Numeric#<} because +5 < RangeExtd::Infinity::POSITIVE+
# raises ArgumentError(!).  In other words, +Integer#<+ does not respect
# +Object#<=>+ but rewrites it.
#
# I do not know if it has been always the case, or some changes have been made
# in more recent versions of Ruby.
#
# Note that +Float#<+ etc need to be redefined individually, because they seem
# not to use +Numeric#<+ any more.
class Numeric

  alias_method :compare_than_numeric_before_infinity?, :<=>  if ! self.method_defined?(:compare_than_numeric_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <=>(c)
    # Default if the special case INFINITY.
    return compare_than_numeric_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_than_numeric_before_infinity?(c)
  end

  alias_method :greater_than_numeric_before_infinity?, :>  if ! self.method_defined?(:greater_than_numeric_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def >(c)
    # Default if self is Complex or something not Integer, Rational, Float or alike
    # or the special case INFINITY.
    return greater_than_numeric_before_infinity?(c) if !self.class.method_defined?(:>) || ((abs rescue self) == Float::INFINITY)

    if RangeExtd::Infinity.infinity? c
      c.negative?
    else
      greater_than_numeric_before_infinity?(c)
    end
  end

  alias_method :less_than_numeric_before_infinity?, :<  if ! self.method_defined?(:less_than_numeric_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <(c)
    # Default if self is Complex or something not Integer, Rational, Float or alike
    # or the special case INFINITY.
    return less_than_numeric_before_infinity?(c) if !self.class.method_defined?(:>) || ((abs rescue self) == Float::INFINITY)

    if RangeExtd::Infinity.infinity? c
      c.positive?
    else
      less_than_numeric_before_infinity?(c)
    end
  end
end  # class Numeric


#
# = class Float
#
# The same as {Numeric#>} and {Numeric#<}.  See them for the background.
class Float

  alias_method :compare_than_float_before_infinity?, :<=>  if ! self.method_defined?(:compare_than_float_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <=>(c)
    # Default if the special case INFINITY.
    return compare_than_float_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_than_float_before_infinity?(c)
  end

  alias_method :greater_than_float_before_infinity?, :>  if ! self.method_defined?(:greater_than_float_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def >(c)
    # Default if self is Complex or something not Integer, Rational, Float or alike
    # or the special case INFINITY.
    return greater_than_float_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    if RangeExtd::Infinity.infinity? c
      c.negative?
    else
      greater_than_float_before_infinity?(c)
    end
  end

  alias_method :less_than_float_before_infinity?, :<  if ! self.method_defined?(:less_than_float_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <(c)
    # Default if self is Complex or something not Integer, Rational, Float or alike
    # or the special case INFINITY.
    return less_than_float_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    if RangeExtd::Infinity.infinity? c
      c.positive?
    else
      less_than_float_before_infinity?(c)
    end
  end
end  # class Float


#
# = class Integer
#
# The same as {Numeric#>} and {Numeric#<}.  See them for the background.
class Integer

  alias_method :compare_than_integer_before_infinity?, :<=>  if ! self.method_defined?(:compare_than_integer_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <=>(c)
    # Default if the special case INFINITY (never happens in Default, but a user may define Integer::INFINITY).
    return compare_than_integer_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_than_integer_before_infinity?(c)
  end

  alias_method :greater_than_integer_before_infinity?, :>  if ! self.method_defined?(:greater_than_integer_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def >(c)
    # Default if self is not comparable (in case the Integer method is redifined by a user).
    return greater_than_integer_before_infinity?(c) if !self.class.method_defined?(:>)

    if RangeExtd::Infinity.infinity? c
      c.negative?
    else
      greater_than_integer_before_infinity?(c)
    end
  end

  alias_method :less_than_integer_before_infinity?, :<  if ! self.method_defined?(:less_than_integer_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <(c)
    # Default if self is not comparable (in case the Integer method is redifined by a user).
    return less_than_integer_before_infinity?(c) if !self.class.method_defined?(:>)

    if RangeExtd::Infinity.infinity? c
      c.positive?
    else
      less_than_integer_before_infinity?(c)
    end
  end
end  # class Integer

