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
  # Note
  #
  #    RangeExtd::Nowhere::NOWHERE == nil     # => true
  #
  # This file does not alter NilClass at all.  It is highly recommended to do
  #
  #    require "+range_extd/nil_class+"
  #
  # so that the behaviours would be comutative. In particular, without requiring it,
  #
  #    nil == RangeExtd::Nowhere::NOWHERE     # => false
  #
  # returns false, which is most likely not convenient.
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

    #def <=>(other)
    #  other.nil?
    #end

    def method_missing(method, *args, &block)
      return nil.send method, *args, &block
    end
  end  # class Nowhere < BasicObject

  Nowhere::NOWHERE = self.const_get(:Nowhere).instance
end	# class RangeExtd < Range

