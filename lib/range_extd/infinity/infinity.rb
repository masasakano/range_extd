# -*- encoding: utf-8 -*-

if ! defined?(Rational)
  require 'rational'	# For Ruby 1.8
end

# This file is required from range_open/range_open.rb
class RangeExtd < Range
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
  # and two more:
  # * FLOAT_INFINITY  (OBSOLETE; workaround for Ruby 1.8 to represent Float::INFINITY)
  # * CLASSES_ACCEPTABLE (see below)
  #
  # There is no other object in this class (you can not create a new one).
  #
  # This class includes Comparable module.
  #
  # ==Description
  #
  # Both the two constant are an abstract value which is always smaller/larger,
  # respectively, than any other Comparable objects (1 or -1 by i{#<=>}(obj))
  # except for infinities with the same polarity, that is, positive or negative,
  # in which case 0 is returned.
  # See the document of the method #{==} for the definition of "infinity".
  # Also, {#succ} is defined, which just returns self.
  #
  # There is a note of caution.
  # The method {#<=>} is defined in this class as mentioned above.
  #  However any operator is, by Ruby's definition, not commutative,
  # unless both the classes define so.
  #
  # There are only two built-in classes that are Comparable: String and Numeric
  # (except for Complex).
  # For String class objects, the #{<=>} operator work as expected
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
  # Please use {Float::INFINITY} instead in principle;
  # it will be a lot faster in run-time, though it is
  # perfectly possible for you to implement the feature
  # in Numeric sub-classes, if need be.
  #
  # Any other Comparable classes are defined by users by definition,
  # whether you or authors of libraries.
  # The comparison with {RangeExtd::Infinity} instances are
  # implemented in {Object#<=>} in this library.  Hence, as long as
  # the method <=> in the classes is written sensibly, that is, if it
  # respects the method of the super-class when it does not know
  # how to deal with an unknown object, there is no need for
  # modification.  Any object in your class (say, YourComparable) 
  # is immediately comparable with the {RangeExtd::Infinity} instances,
  #    YourComparable.new <=> RangeExtd::Infinity::POSITIVE    # => -1
  #    RangeExtd::Infinity::POSITIVE <=> YourComparable.new    # => 1
  # except for the infinity inscances in YourComparable (see #{==}).
  #
  # See the document in {Object#<=>} in this code/package for detail.
  #
  # However, some existing Comparable classes, perhaps written by some
  # one else may not be so polite, and has disabled comparison
  # with any object but those intended.  Unlucky you!
  # 
  # For that sort of circumstances,
  # the class method {RangeExtd::Infinity.overwrite_compare} provides
  # a convenient way to overcome this problem to make
  # the operator <=> commutative for a given Comparable class.
  #
  # Note {RangeExtd::Infinity.overwrite_compare} does nothing for the classes
  # registered in the Class constant Array {RangeExtd::Infinity::CLASSES_ACCEPTABLE}.
  # So, if you want to avoid such modification of the method <=>, perhaps
  # by some other end users, you can register the class in that array.
  #
  # Only the methods defined in this class are
  # {#===}, {#==}, {#<=>}, {#succ}, {#to_s}, {#inspect},
  # {#infinity?}, {#positive?} and {#negative?}.
  #
  # Note that the unary operand {#-@} is not defined.
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

    # Class that accept to be compared with Infinity instances.
    CLASSES_ACCEPTABLE = [self, Float, Fixnum, Bignum, Rational, Numeric, String]	# , BigFloat

    def infinity?
      true
    end
  
    def positive?
      @positive 
    end
  
    def negative?
      !@positive 
    end

    alias :cmp_before_rangeextd_infinity? :==  if ! self.method_defined?(:cmp_before_rangeextd_infinity?)	# No overwriting.

    # Always -1 or 1 except for itself and the corresponding infinities (== 0).  See {#==}.
    # Or, nil (as defined by Object), if the argument is not Comparable, such as, nil and IO.
    # @return [Integer] or possibly nil.
    def <=>(c)
      if c.nil?
        super
      elsif !defined?(c.<=)	# Not Comparable?
        super
      elsif @positive 
        if self == c
          0
        else
          1
        end
      else	# aka negative
        if self == c
          0
        else
          -1
        end
      end
    end
  
    # Always false except for itself and the corresponding {Float::INFINITY}
    # and those that have methods of {#infinity?} and {#positive?}
    # with the corresponding true/false values, in which case this returns true.
    def ==(c)
      if (Infinity === c)
        (@positive ^! c.positive?)	# It should be OK to compare object_id?
      elsif c ==  FLOAT_INFINITY &&  @positive
        true
      elsif c == -FLOAT_INFINITY && !@positive
        true
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
  
    # @return [Infinity] self
    def succ
      self
    end
  
    # @return [String]
    def inspect
      if @positive 
        "INFINITY"
      else
        "-INFINITY"
      end
    end
  
    alias :to_s :inspect
  

  # Overwrite "<=>" method of the given class, if necessary,
  # to make its instances be comparable with RangeExtd::Infinity objects (constants).
  # For example,
  #   RangeExtd::Infinity::NEGATIVE.<=>(any_comparable)
  # always gives back -1 (except for same infinities).  However the other way around,
  #   SomeClass.new.<=>(RangeExtd::Infinity::NEGATIVE)
  # usually returns nil, which is not handy.
  # Therefore, this function (Class method) provides a convenient
  # way to overcome it, that is, if the given class
  # (or the class of the given object) is Comparable,
  # its "<=>" method is modified (and true is returned),
  # unless it has been already done so, or some classes as listed below,
  # such as Numeric and String, in which case nil is returned.
  # If it is not Comparable, false is returned.
  # The judgement whether it is Comparable or not is based
  # whether the class has an instance method ThatClass#<=
  #
  # In processing, this method first looks up at an Array
  # {RangeExtd::Infinity::CLASSES_ACCEPTABLE},
  # and if the given class is registered in it,
  # it does nothing.  If not, and if all the othe conditions
  # are met, it overwrites its <=> method and register
  # the class in the array.
  #
  # @param obj [Object] Either Class or its object.
  # @return [Boolean] or possibly nil (see the description).
  def self.overwrite_compare(obj)
    if defined? obj.instance_methods
      klass = obj
    else
      klass = obj.class

      begin
        1.0 + obj	# Use  "rescue ArgumentError"  if using "1.0<obj"
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
  alias :compare_before_infinity :==  if ! self.method_defined?(:compare_before_infinity)
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


    private
  
    def initialize(t)
      @positive = (t && true)
    end
  
    NEGATIVE = new(false)
    POSITIVE = new(true)

    #NEGATIVE.freeze
    #POSITIVE.freeze

  end	# class Infinity
  
  
  class Infinity
    # Disable new() so no other object will be created.
    private_class_method :new
  
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
# Overwrite Object#<=>() so all its sub-classes can be
# aware of RangeExtd::Infinity objects (the two constants).
#
class Object
  alias :compare_obj_before_infinity :==  if ! self.method_defined?(:compare_obj_before_infinity)	# No overwriting.

  # Overwrite #{Object#<=>}().  Then, all its sub-classes can be
  # aware of RangeExtd::Infinity objects (the two constants).
  #
  # In this definition of "<=>", if self is Comparable
  # (by judging whether it has the method "<="),
  # it always returns, unless infinity? and positive? are set
  # accordingly, either -1 or 1, depending which of
  #   RangeExtd::Infinity::(NEGATIVE|POSITIVE)
  # is compared.  If self is not Comparable, the original "<=>"
  # is called, which should return nil (unless both the object_id
  # agree, eg., nil and nil, in which case 0 is returned).
  #
  # If you define your own class, which is Comparable, you should
  # define the method "<=>" as follows, as in the standard practice
  # when you redefine a method that exists in a superclass;
  #
  #    class MyComparableClass 
  #      include Comparable
  #      # alias :cmp_orig :<=> if !self.method_defined?(:cmp_orig)	# if you want
  #      def <=>(c)
  #        if c._is_what_i_expect?
  #          # Write your definition.
  #        else       # When self does not know what to do with c.
  #          super    # to call Object#<=>
  #        end
  #      end
  #    end
  #
  def <=>(c)
    if defined?(self.<=) && RangeExtd::Infinity === c
      # if defined?(self.<=) && defined?(c.infinity?) && defined?(c.positive?)
      # NOTE: Duck-typing is inappropriate here.
      #   Only the objects that self wants to deal with here are
      #   the instances of RangeExtd::Infinity, and not other
      #   "infinity" object, such as, Float::INFINITY.  So,
      #     (self <=> RangeExtd::Infinity::POSITIVE)  # => -1
      #     (self <=> Float::INFINITY)                # => nil
      #   in default.
      if defined?(self.infinity?) && defined?(self.positive?)
        if (self.positive? ^! c.positive?)
          0
        elsif self.positive?
          1
        else
          -1
        end
      else
        # (c <=> self) * (-1)
        if c.positive?
          -1
        else
          1
        end
      end
    elsif object_id == c.object_id	# (nil <=> nil)  # => 0
      0
    else
      nil
    end	# if defined?(self.<=) && RangeExtd::Infinity === c
  end	# def <=>(c)
end	# class Object


