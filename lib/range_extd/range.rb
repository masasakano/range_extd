# -*- encoding: utf-8 -*-

#== Summary
#
# Modifies {#==} and add methods of
# {#valid?}, {#empty?}, {#null?}, {#is_none?} and {#is_all?}.
#
class Range

  alias_method :equal_prerangeextd?, :==  if ! self.method_defined?(:equal_prerangeextd?)	# No overwriting.

  # It is extended to handle {RangeExtd} objects.
  # For each element, that is, +Range#begin+ and +Range#end+,
  # this uses their method of ==().
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

  ## Same as {#==}, but the comparison is made with eql?() method.
  #def eql?(r)
  #  _equal_core(r, :eql?, :eql_prerangeextd?)
  #end

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
  #   (true..true).empty?# => nil
  #   (1...1).empty?     # => nil
  #   (1..1).empty?      # => false
  #   RangeExtd(1...1,   true).empty? # => true
  #   RangeExtd(1...2,   true).empty? # => true
  #   RangeExtd(1.0...2, true).empty? # => false
  #   RangeExtd(?a...?b, true).empty? # => true
  #   RangeExtd::NONE.empty?          # => true
  #
  # @note {#empty?} returns nil when the object is invalid, and hence invalid objects
  #   may appear to be not empty. If you want to get +true+ when the object is either
  #   empty or invalid, use {#null?} instead.
  #
  # See {#valid?} and {RangeExtd.valid?} for the definition of the validity.
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


  # Returns true if it is either empty or invalid, or false otherwise.
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
  # true if self is identical (+eql?+) to {RangeExtd::ALL}
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
    return false if !_both_same_nowhere_parity?(r)  # inconsistent nil, non-nil, NOWHERE combination
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

  # Returns the parity of both ends in Range with regard to {RangeExtd::Nowhere::NOWHERE}, non-nil, nil
  #
  # For example,
  # if both begins are non-nil and both ends are {NilClass} nil, this returns true.
  # If one end {RangeExtd::Nowhere::NOWHERE} the other end is {NilClass} nil, returns false
  #
  # Note that boundaries are not taken into account in this routine.
  # If, for example, {#exclude_end?} contradict, regardless of the returne
  # value of this routine, it should not be "equal".  The caller must handle it.
  #
  # == Background
  #
  # Although {RangeExtd::Nowhere::NOWHERE} looks like nil, it is different
  # in the context of {Range} and is used only for representing *nowhere*.
  # Therefore, it should be recognised as a different value from nil.
  #
  # @param other [Range, RangeExtd] Other object to compare with
  def _both_same_nowhere_parity?(other)
    p_self_begin = _parity_nowhere_nonnil_nil( self.begin)
    p_othe_begin = _parity_nowhere_nonnil_nil(other.begin)
    p_self_end   = _parity_nowhere_nonnil_nil( self.end)
    p_othe_end   = _parity_nowhere_nonnil_nil(other.end)

    (p_self_begin == p_othe_begin) && (p_self_end == p_othe_end)
  end
  private :_both_same_nowhere_parity?

  # Core routine for {#_both_same_nowhere_parity?} to determine the parity of a value
  #
  # Note that RangeExtd::Infinity objects are regarded as +nil+.
  #
  # @return [Integer] (-1, 0, 1) for {RangeExtd::Nowhere::NOWHERE}, non-nil, nil respectively.
  def _parity_nowhere_nonnil_nil(val)
    return 0 if !val.nil? && !RangeExtd::Infinity.infinity?(val)
    (val.respond_to?(:nowhere?) && val.nowhere?) ? -1 : 1
  end
  private :_parity_nowhere_nonnil_nil
end	# class Range

require_relative "../range_extd" if !defined?(RangeExtd)

