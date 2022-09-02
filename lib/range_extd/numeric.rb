require_relative "infinity" if !defined?(RangeExtd::Infinity)

#
# = class Numeric
#
# Modify {Numeric#>} and {Numeric#<} and {Numeric#<=>} because +5 < RangeExtd::Infinity::POSITIVE+
# raises ArgumentError(!).  In other words, +Integer#<+ does not respect
# +Object#<=>+ but rewrites it.
#
# I do not know if it has been always the case, or some changes have been made
# in more recent versions of Ruby.
#
# Note that +Float#<+ etc need to be redefined individually, because they seem
# not to use +Numeric#<+ any more.
#
# To activate these features, explicitly do one of the following
#   require "range_extd/numeric"
#   require "range_extd/object"
#   require "range_extd/load_all"
#
class Numeric

  # Backup of the original {Numeric#<=>}
  alias_method :compare_than_numeric_before_infinity?, :<=>  if ! self.method_defined?(:compare_than_numeric_before_infinity?)
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <=>(c)
    # Default if the special case INFINITY.
    return compare_than_numeric_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_than_numeric_before_infinity?(c)
  end

  # Backup of the original {Numeric#>}
  alias_method :greater_than_numeric_before_infinity?, :>  if ! self.method_defined?(:greater_than_numeric_before_infinity?)
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

  # Backup of the original {Numeric#<}
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

  # Backup of the original {Float#<=>}
  alias_method :compare_than_float_before_infinity?, :<=>  if ! self.method_defined?(:compare_than_float_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <=>(c)
    # Default if the special case INFINITY.
    return compare_than_float_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_than_float_before_infinity?(c)
  end

  # Backup of the original {Float#>}
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

  # Backup of the original {Float#<}
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

  # Backup of the original {Integer#<=>}
  alias_method :compare_than_integer_before_infinity?, :<=>  if ! self.method_defined?(:compare_than_integer_before_infinity?)	# No overwriting.
  # Special case for comparison with a {RangeExtd::Infinity} instance.
  def <=>(c)
    # Default if the special case INFINITY (never happens in Default, but a user may define Integer::INFINITY).
    return compare_than_integer_before_infinity?(c) if ((abs rescue self) == Float::INFINITY)

    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_than_integer_before_infinity?(c)
  end

  # Backup of the original {Integer#>}
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

  # Backup of the original {Integer#<}
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

