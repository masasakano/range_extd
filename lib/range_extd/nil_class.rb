# -*- encoding: utf-8 -*-

# Adds a couple of methods in NilClass and modifies the behaviour +==+ slightly
# so that it returns true for nil-equivalent objects if they return true for +nil?+
#
# In default, it seems the judgement is based on +other.__id__+.
# Note that the method +eql?+ (and of course +equal?+) unchange.
#
# Here is the summary of the changes:
#
# * {NilClass#nowhere?} is added, which returns +false+.
# * {NilClass#class_raw} is added, which returns {NilClass}
# * +(nil == RangeExtd::Nowhere::NOWHERE)+ returns +true+
#
# To activate these features, explicitly do either of the following
#   require "range_extd/nil_class"
#   require "range_extd/load_all"
#
class NilClass
  # returns true
  def nowhere?
    false
  end

  # Identical to +nil.class+
  #
  # @return [Class]
  def class_raw
    self.class
  end

  alias_method :double_equals?, :==  if ! self.method_defined?(:double_equals?)	# No overwriting.

  # returns true if other returns true with +nil?+.
  #
  # @return [Boolean]
  def ==(other)
    other.nil?
  end
end

