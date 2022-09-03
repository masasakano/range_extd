# -*- encoding: utf-8 -*-

require "singleton"

if ! defined?(Rational)
  require 'rational'	# For Ruby 1.8
end

## NOTE: Write nothing for the class description of RangeExtd, because it would have a higher priority for yard!


class RangeExtd < Range

  #
  # =Class RangeExtd::Nowhere
  #
  # Authors:: Masa Sakano
  # License:: MIT
  #
  # ==Summary
  #
  # Singleton Class to host a unique value that behaves like +nil+ except
  # for a couple of methods to distinguish itself from +nil+ and except
  # that it is not regarded as the false value in conditional statements.
  #
  # ==Description
  #
  # The unique value is obtained with {RangeExtd::Nowhere.instance} and is
  # also available as the class constant:
  # {RangeExtd::Nowhere::NOWHERE}
  #
  # The instance behaves exactly like +nil+ except for the behaviour of the false value
  # in the conditional statement (because unfortunately there is no way in Ruby
  # to make the object behave like false/nil in the conditional statement;
  # see {https://stackoverflow.com/a/14449380/3577922}) and except for some methods
  # that are defined in +BasicObject+, such as +__id__+ (n.b., by contract, +object_id+
  # of this class's instance would return the identical id to nil's),
  # and two custom methods:
  #
  # * {#nowhere?} returns +true+
  # * {#class_raw} returns this class (n.b., the standard +class+ method returns +NilClass+).
  #
  # and the equality behaviour with +eql?+, that is,
  #
  #    RangeExtd::Nowhere::NOWHERE.eql?(nil)  # => false
  #
  # whereas
  #
  #    RangeExtd::Nowhere::NOWHERE == nil     # => true
  #
  # This file in itself does not alter NilClass at all.  It is highly recommended to do
  #
  #    require "range_extd/nil_class"
  #
  # to implement these additional features in {NilClass} so that the behaviours
  # would be comutative. In particular, without requiring it,
  #
  #    nil == RangeExtd::Nowhere::NOWHERE     # => false
  #
  # returns false, which is most likely not convenient.
  # In practice, if you require "+range_extd+", the file is also automatically required
  # and so you do not have to worry about it, unless you decide to use this class
  # independently of the main {RangeExtd}.
  #
  # ==Note about the behaviour in conditional statements
  #
  # The (sole) instance of this class behaves like +true+ like in the conditional statement unlike +nil+
  # which behaves like the false value. Unfortunately, there is no way in Ruby
  # to make an object behave like false/nil in the conditional statement;
  # see {https://stackoverflow.com/a/14449380/3577922}.  In the conceptual sense,
  # however, the difference should not be a problem.  If one checks whether
  # a {Range} (say, +range+) is beginless/endless on the basis of its begin/end value,
  # the judgement should be based on the method +nil?+ or its equivalent like
  #
  #   if range.begin.nil?
  #
  # and *not*
  #
  #   if !range.begin
  #
  # because the latter does not distinguish +(..a)+ and +(false..false)+.
  #
  class Nowhere < BasicObject
    include ::Singleton
  
    # returns true
    def nowhere?
      true
    end

    # returns this class {RangeExtd::Nowhere}
    #
    # Note that the standard +class+ method returns +NilClass+
    #
    # @return [Class]
    def class_raw
      ::RangeExtd::Nowhere
    end

    # returns true if other is nil.
    #
    # @return [Boolean]
    def ==(other)
      other.nil?
    end

    # returns false if other is the standard nil of NilClass.
    def eql?(other)
      self.equal? other
    end

    ## '==' is reflected, hence no need to define.
    #def <=>(other)
    #  other.nil?
    #end

    # The hash value is adjusted, which is not strictly guaranteed to be unique, though in pracrtice it is most likely to be so.
    #
    # Even without this, `nil.eql?` would return false.  However,
    # it is a special case. Without this, the hash value of {RangeExtd::NONE} 
    # would be the same as that of +RangeExtd(..nil, true)+.
    #
    # @return [Integer]
    def hash(*args)
      nil.send(:hash, *args) - 1
    end

    def method_missing(method, *args, &block)
      return nil.send method, *args, &block
    end
  end  # class Nowhere < BasicObject

  Nowhere::NOWHERE = self.const_get(:Nowhere).instance
end	# class RangeExtd < Range

