# -*- encoding: utf-8 -*-

#
# = class Object
#
# Overwrite {Object#<=>}() so all its sub-classes can be
# aware of {RangeExtd::Infinity} objects (the two constants).
#
# To activate these features, explicitly do either of the following
#   require "range_extd/object"
#   require "range_extd/load_all"
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
  #          super c  # to call Object#<=> or its descendant's
  #        end
  #      end
  #    end
  #
  def <=>(c)
    return (-(c.send(__method__, self) || return)) if RangeExtd::Infinity.infinity? c
    compare_obj_before_infinity(c)
  end	# def <=>(c)
end	# class Object

require_relative "infinity" if !defined?(RangeExtd::Infinity)

