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
  # Class to hold just two main constants: 
  # * RangeExtd::Infinity::NEGATIVE
  # * RangeExtd::Infinity::POSITIVE
  #
  # and two internal ones:
  #
  # * CLASSES_ACCEPTABLE (see below)
  # * FLOAT_INFINITY  (OBSOLETE; workaround for Ruby 1.8 to represent Float::INFINITY)
  #
  # There are no other objects in this class (you cannot create a new one).
  #
  # This class includes +Comparable+ module.
  #
  # ==Description
  #
  # Both the two constant are abstract values which are always smaller/larger,
  # respectively, than any other Comparable objects (1 or -1 by i{#<=>}(obj))
  # except for infinities with the same polarity, that is, positive or negative,
  # in which case 0 is returned.
  # See the document of the method {#==} for the definition of "infinity".
  #
  # +Infinity#succ+ used to be defined up to {RangeExtd} Ver.1 but is removed in Ver.2.
  #
  # There is a note of caution.
  # The method {#<=>} is defined in this class as mentioned above.
  # However, any operator is, by Ruby's definition, not commutative
  # unless both the classes define so.
  #
  # There are only three built-in classes that are Comparable: String, Time and Numeric
  # (except for Complex).
  # Note Date and DateTime objects are so, too, however they need "require",
  # hence are (and must be) treated, in the same was as with any other classes.
  #
  # But whether String, Time, or Numeric class objects, the [#<=>] operator
  # does work in the commutative way with the instances of this class.
  #    ?z <=> RangeExtd::Infinity::POSITIVE    # => nil
  #    RangeExtd::Infinity::POSITIVE <=> ?z    # => 1.
  #    50 <=> RangeExtd::Infinity::POSITIVE    # => nil
  #    RangeExtd::Infinity::POSITIVE <=> 50    # => 1.
  #
  # For this reason, for example,
  #   (50 .. RangeExtd::Infinity::POSITIVE)
  # raises an exception, because the Numeric instance 50 does not
  # know how to compare itself with a {RangeExtd::Infinity} instance,
  # and {Range} class does not allow such a case.
  #
  # To mitigate the inconvenience,
  # this package provides helper libraries +range_extd/object+
  # and +range_extd/numeric+ (or all-inclusive wrapper +range_extd/load_all+).
  # If your code requires them, [#<=>] operators in String and Numeric
  # will work commutatively with {RangeExtd::Infinity}.
  # Note that external gem for Numeric like +BigFloat+, if you require it, may not work
  # straightaway and so the following measure needs to be taken.
  #
  # Once the library +range_extd/object+ has been required (your code must 
  # explicitly include the statement +require "range_extd/object"+,
  # unless your code requires +range_extd/load_all+),
  # which redefines {Object#<=>} so that the operator in any descendant
  # class works in a commutative way with {RangeExtd::Infinity} instances.
  #    YourComparable.new <=> RangeExtd::Infinity::POSITIVE    # => -1
  #    RangeExtd::Infinity::POSITIVE <=> YourComparable.new    # => 1
  # The condition for it is, though, the method [#<=>] in the descendant class is
  # written in a sensible manner, that is, it respects the method of
  # the super-class when it does not know
  # how to deal with a given object.
  #
  # However, some existing Comparable classes, perhaps written by some
  # one else may not be so polite, and has disabled comparison
  # with any object but those intended.  Unlucky you!
  # Indeed, the classes like Date and DateTime are one of them.
  #
  # For that sort of circumstances,
  # the class method {RangeExtd::Infinity.overwrite_compare} provides
  # a convenient way to overcome the problem to (dynamically) make
  # the operator [#<=>] commutative for a given Comparable class.
  #
  # Note {RangeExtd::Infinity.overwrite_compare} does nothing for the classes
  # registered in the Class constant Array {RangeExtd::Infinity::CLASSES_ACCEPTABLE}.
  # So, if you want to avoid such modification of the method [#<=>], perhaps
  # by some other end users, you can register the class in the array.
  #
  # Only the instance methods defined in this class are
  # {#===}, {#==}, {#<=>}, {#to_s}, {#inspect},
  # {#infinity?}, {#positive?} and {#negative?}. In addition, since Version 1.1,
  # two unary operators {#@+} and {#@-} to unchange/swap the parity are defined,
  # (the reason why {#<} and {#>} are modified is to deal with Integer and Float;
  # I do not know whether the default behaviour of these classes have changed
  # in the recent versions of Ruby, though).
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
  # Therefore, all of the following are true ({Object#<=>} and some methods
  # in some classes are modified)
  #
  #   (RangeExtd::Infinity::POSITIVE > 5)
  #   (RangeExtd::Infinity::NEGATIVE < 5)
  #
  #   (RangeExtd::Infinity::POSITIVE > "a")
  #   (RangeExtd::Infinity::NEGATIVE < "a")
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

    # Backup of the original method {RangeExtd::Infinity#==}
    alias_method :cmp_before_rangeextd_infinity?, :==  if ! self.method_defined?(:cmp_before_rangeextd_infinity?)

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

    # Backup of the original method {RangeExtd::Infinity#>}
    alias_method :greater_than_before_rangeextd_infinity?, :>  if ! self.method_defined?(:greater_than_before_rangeextd_infinity?)
    # Special case for Float::INFINITY
    #
    #   (Float::INFINITY > RangeExtd::Infinity::POSITIVE)
    # raises ArgumentError and so does this method.
    def >(c)
      ((c.abs rescue c) == Float::INFINITY) ? raise(ArgumentError, "RangeExtd::Infinity object not comparable with '#{__method__}' with Float::INFINITY") : greater_than_before_rangeextd_infinity?(c)
    end

    # Backup of the original method {RangeExtd::Infinity#<}
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
  #
  # to make its instances be comparable with RangeExtd::Infinity objects (constants).
  # For example,
  #   RangeExtd::Infinity::NEGATIVE.<=>(any_comparable)
  # always gives back -1 (except for same infinities).  However the other way around,
  #   SomeClass.new.<=>(RangeExtd::Infinity::NEGATIVE)
  # usually returns nil, which is not handy.
  #
  # Therefore, this function (Class method) provides a convenient
  # way to overcome it, that is, if the given class
  # (or the class of the given object) is Comparable
  # and returns +nil+ when compared with {RangeExtd::Infinity}
  # (note that such a check is only possible when an instance is given
  # given to this method as the argument),
  # its [#<=>] method is modified (and true is returned),
  # unless it has been already done so, or it is one of the classes listed below,
  # such as Numeric and String, in which case nil is returned.
  # If it is not Comparable, false is returned. If +<=>+ returns
  # something other than nil, nil is returned (for it likely
  # means the class already recognises {RangeExtd::Infinity}).
  # The judgement whether it is Comparable or not is based
  # whether the class has an instance method +ThatClass#<=+
  #
  # In processing, this method first looks up at an Array
  # {RangeExtd::Infinity::CLASSES_ACCEPTABLE},
  # and if the given class is registered in it,
  # it does nothing.  If not, and if all the other conditions
  # are met, it overwrites its <=> method and register
  # the class in the array.
  #
  # @param obj [Object] Either Class or its instance. An instance is recommended, because an additional check is possible.
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

      begin
        cmpval = (obj <=> self::POSITIVE)
        return nil if !cmpval.nil?  # the instance recognises RangeExtd::Infinity
      rescue NoMethodError
        return false    # <=> is not defined (explicitly disabled, apparently).
      rescue
        # If the comparison with Infinity raises an Exception, the method will be modified here.
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
    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_before_infinity(c)
  end
__EOF__

      klass.class_eval(code)

      true
    end # if !a.include?( :<= )	# NOT Comparable
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
  # Note +Float#infinite?+ is defined - maybe that helps to memorise this method name
  # (as opposed to +infinity?+)?
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

