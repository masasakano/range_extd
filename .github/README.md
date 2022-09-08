
# RangeExtd - Extended Range class with exclude_begin and open-ends

## Introduction

This package contains RangeExtd class, the Extended Range class that features:

1.  includes exclude_begin? (to exclude the "begin" boundary),
2.  allows open-ended range to the infinity (**not** undefined ends, i.e.,
    `nil`),
3.  defines NONE and ALL constants,
4.  the first self-consistent logical range structure in Ruby,
5.  complete compatibility within the built-in Range.


With the introduction of the excluded status of begin, in addition to the end
as in built-in Range, and open-ended feature, the logical completeness of the
1-dimensional range is realised.

A major pro of this library is application to logical operations of multiple
ranges, most typically Float and/or Rational.
[Rangeary](https://rubygems.org/gems/rangeary) uses this library to fullest to
realise the concept of logical range operations. In doing them, the concept of
potentially open-ended Ranges with potential exclusions of begin and end is
essential.  For example, the negation of Range `(?a..?d)` is a pair of Ranges
`(-"Infinity-Character"...3)` and `(?d(exclusive).."Infinity-Character")` and
its negation is back to the original `(?a..?d)`.  Such operations are possible
only with this class `RangeExtd` 

Rangeary: {https://rubygems.org/gems/rangeary}

The built-in Range class is very useful, and has given Ruby users a power to
make easy coding.  Yet, the lack of definition of exclusive begin boundary is
a nuisance in some cases.

Having said that, there is a definite and understandable reason; Range in Ruby
is not limited at all to Numeric (or strictly speaking, Real numbers or their
representatives).  Range with any object that has a method of `succ()` is
found to be useful, whereas there is no reverse method for `succ()` in
general. In that sense Range is inherently not symmetric.  In addition, some
regular Range objects are continuous (like Float), while others are discrete
(like Integer or String).  That may add some confusion to the strict
definition.

To add the feature of the exclusive-begin boundary is in that sense not 100
per cent trivial.  The definition I adopt for the behaviour of {RangeExtd} is
probably not the only solution.  Personally, I am content with it, and I think
it achieves the good logical completeness within the frame.

I hope you find this package to be useful.

### Validity of a Range

Ruby built-in Range is very permissive for the elements (members).  For
example, `(true...true)` is a valid Range whatever it means, although its use
is highly limited because you cannot iterate over it, that is, methods like
`each` with an associated iterator and `to_a` would raise an Exception
(`TypeError`).

With this library, the validity of a Range is strictly defined. This library
adds a few methods, most notably {Range#valid?}, {Range#null?} and
{Range#empty?} to Range class, which would take immediate effect in any of its
sub-classes.

As an example, `(3...3).valid?`  returns false, because the element 3 is
inclusive for the begin boundary, yet exclusive for the end boundary, which
are contradictory to each other.  With this RangeExtd class, the following two
are regarded as valid ranges,

```ruby
* RangeExtd.new(3, 3, true,  true)   # => an empty range
* RangeExtd.new(3, 3, false, false)  # => a single-point range (3..3)
```

However, as long as the use is closed within the built-in Range, nothing has
changed, so it is completely compatible with the standard Ruby.

### Open-ended ranges to infinity

Ruby 2.6 and 2.7 have introduced endless and beginless Ranges, respectively.
The difference between borderless Ranges and open-ended ranges to infinity
introduced in this library is subtle and perhaps more conceptual or
philosophical than meaningful in the practical term (see Section "Background"
for detail).  Fear not, though. In practical applications, they are compatible
and you do not have to be aware of them.  In short, you can mostly use
built-in borderless Ranges unless you want otherwise.

To express open-ended ranges defined in this library, you use either of the
two (negative and positive, or former and later) constants defined in the
class {RangeExtd::Infinity}

*   {RangeExtd::Infinity::NEGATIVE}
*   {RangeExtd::Infinity::POSITIVE}


They are basically the objects that **generalize** `Float::INFINITY` to any
Comparable object.  For example,

```ruby
("a"..RangeExtd::Infinity::POSITIVE).each
```

gives an infinite iterator with `String#succ`, starting from "a" (therefore,
make sure to code so it breaks the iterator at one stage!). In this case it
work in an identical way to (a Ruby-2.6 form of)

```ruby
("a"..).each
```

### News: Library locations and support of beginless Ranges

**IMPORTANT**: The paths for the libraries are moved up by one directory in
{RangeExtd} Ver.2 from Ver.1 in order that their locations follow the Ruby
Gems convention.  In short, the standard way to require is `require "range_extd"`, the path of which used to be "range_extd/range_extd"

Version of {RangeExtd} is now 2.0.

Here is a brief summary of other significant changes in recent upgrades. For
more extensive information, see History section in this doc.

#### News: Beginless Range supported

Ruby 2.7 supports [Beginless range](https://rubyreferences.github.io/rubychanges/2.7.html#beginless-range).

`RangeExtd` also supports it now. With this, there are important changes in
specification.

First, {RangeExtd::NONE} is now in practice
`RangeExtd((RangeExtd::Nowhere::NOWHERE...RangeExtd::Nowhere::NOWHERE), true)`, that is, both ends are {RangeExtd::Nowhere::NOWHERE} and both ends
({RangeExtd#begin} and {RangeExtd#end}) are exclusive. In the previous
versions, both ends of {RangeExtd::NONE} used to have `nil`. Range
`(nil..nil)` did not use to be allowed in Ruby-2.6 or earlier, and hence it
was unique to {RangeExtd::NONE}, conveniently. However, Ruby-2.7 and later now
accepts nil to nil Range.  Then, `(nil..nil)` is perfectly valid and it has in
practice no difference from `RangeExtd((nil...nil), true)`, which used to be
the form of {RangeExtd::NONE}, despite the fact the former is a completely
different object that is close to {RangeExtd::ALL} except for the exclusion
flags.  That is why this change is required.

Having said that, this change is majorly conceptual and there is almost no
change from users' point of view. The begin and end value for
{RangeExtd::NONE}, {RangeExtd::Nowhere::NOWHERE}, behaves almost exactly like
{NilClass} (see Description below for detail). Given that the value was
literally `nil` in {RangeExtd} Ver.1 and earlier, the use of
{RangeExtd::Nowhere::NOWHERE} in {RangeExtd::NONE} in Ver.2 should not demand
any changes in the existing code that use {RangeExtd::NONE}. The recommended
way to check whether an object is {RangeExtd::NONE} or not with use of
{RangeExtd#is_none?} (as it always has been) (do not be confused with
`Enumerable#none?`). Or, in most practical cases, {Range#null?} is likely to
be what a user wants (n.b., a potential caveat is `(true..true).null?` returns
`false`; see subsection "RangeExtd Class" in "Description" in this doc for
detail).

Second, `RangeExtd.valid?(nil..)` now returns `true`, which used to be
`false`, and it is equal to {RangeExtd::ALL}.

For example, `"[abc"](nil..)` is a perfectly valid Ruby expression in Ruby-2.7
and later, though it used to be invalid or even SyntaxError in earlier
versions of Ruby. Hence it would be strange if `RangeExtd` considered it
invalid.

Note that `RangeExtd.valid?(true..)` still returns `false`.

Other major changes in specification include:

*   `RangeExtd::Infinity#succ` is now undefined, in line with Float.
*   Extensions for `Object` and `Numeric` are now not in default and optional.
*   `RangeExtd#eql?` follows the Ruby default behaviour (comparison based on
    [#hash]), eliminating special cases in comparison with {RangeExtd::NONE}.
*   Fixed a bug where `RangeExtd#min_by` (and `max_by` and `minmax_by`) did
    not work correctly.


#### News: Endless Range supported

Now, as of 2019 October, this fully supports [Endless Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
introduced in Ruby 2.6.  It is released as Version 1.* finally!

#### NOTE: Relationship with Rangesmaller

This package RangeExtd supersedes the obsolete
[Rangesmaller](https://rubygems.org/gems/rangesmaller) package and class, with
the added open-ended feature and different interfaces in creating a new
instance. {https://rubygems.org/gems/rangesmaller}

## Background

### Endless and Beginless Ranges

[Endless Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
and [Beginless Range](https://rubyreferences.github.io/rubychanges/2.7.html#beginless-range)
were introduced in Ruby 2.6 and 2.7, respectively, released in Decembers 2018
and 2019.

Thanks to them, the Ruby built-in `Range` has achieved part of the
functionalities and concept of what `RangeExtd` provides. However, there are
still some differences, some of which are clear but some are more obscured.

The most clear advantage of this library is the support for `exclude_begin?`
(to exclude the "begin" boundary).

As for the boundary-less Ranges, this library offers, in a word, the
abstraction of open-ended range (to the infinity). A major conceptual
difference is that Ruby's built-in beginless/endless `Range` provides
**undefined** boundaries, whereas `RangeExtd` does **infinite** boundaries.

The difference is subtle but significant. Let us take a look at some examples
of the standard Ruby, particularly Numeric, because Ruby Ranges for Numeric
practically provide both functionalities. These examples highlight the
difference:

```ruby
"abcdef"[..2]   # => "abc"
"abcdef"[..2.0] # => "abc"
"abcdef"[(-Float::INFINITY)..2]  # raise (RangeError)
"abcdef"[(-1)..2] # => ""
"abcdef"[(-6)..2] # => "abc"
"abcdef"[(-7)..2] # => nil
(-Float::INFINITY..5).first(1) # raise: can't iterate from Float (TypeError)
(-Float::INFINITY..5).first    # => -Infinity
(-Float::INFINITY..5).begin    # => -Infinity
(..5).first   # raise: cannot get the first element of beginless range (RangeError)
(..5).begin   # => nil
```

The first (and second) examples use a beginless Range, where the begin value
is **undefined**. Then, String class **interprets** the "begin value" as 0. 
By contrast, the third example raises an Exception; it is understandable
because the begin value is defined but infinitely negative. Indeed, a negative
value for the index for a String has a special meaning as demonstrated in the
4th to 6th examples.

The last five examples are interesting. `Range#begin` simply returns the
begin-boundary value always. `Range#first` returns the first "element" when no
argument is given; `(Float::INFINITY..5)` has the first element and so it is
returned. A beginless {Range} is a different story; it does not have a defined
first element and hence `Range#first` raises `RangeError`. By contrast, When
an argument `n` is given to `Range#first`, an Array of `n` elements should be
returned.  Since counting from any Float is undefined, the Range from the
negative infinity raises `TypeError`.  It makes sense?

By the way, I note that `(5..8.6).last(2)` is valid and returns `[7, 8]` and
`(2.2..8.6).size` is also valid, to add confusion.

Another point is, although the infinity has a clear mathematical definition,
not all Ranges accept it. Let us consider your own subset class where each
instance has only a single lower-case alphabet character and where a Range of
instances can be defined in the same way as the String class. Then, the
minimum begin value and maximum end value the Range can have are "`a`" and
"`z`", respectively. In this case, what would the positive (or negative)
infinities mean?  Perhaps, in the strictest term, the infinities for the Range
should be invalid? Or, the positive infinity should be interpreted as the
index for "`z`" in this case, or else?

Conceptually, the inclusive interpretation is more convenient. Indeed,
[Rangeary](https://rubygems.org/gems/rangeary) uses `RangeExtd` in such a way,
that is, the negation of the Range is actively used for logical operations of
Arrays of Ranges.  However, you cannot force each application to accept the
definition.

In summary, **undefined** boundaries are undefined by definition and their
interpretations are up to each application, whereas positive or negative
infinities may have clear definitions although more flexible interpretations
may be preferred in practical applications.

Given all these, {RangeExtd::Infinity::NEGATIVE} and
{RangeExtd::Infinity::POSITIVE} in this library behaves like `nil`, though it
is possible for users to distinguish them.

### Behaviours of endless and beginless Ranges

The behaviours of the built-in Endless/Beginless Range can be a little
confusing. In addition, it seems there are bugs for `Range#size` ([Bug #18983](https://bugs.ruby-lang.org/issues/18983) and
    {Bug #18993}[https://bugs.ruby-lang.org/issues/18993])

or at least points that contradict the specification described in the official
doc, which adds confusion.

In the Ruby implementation, the begin and end values of a beginless and
endless Ranges are both interpreted as `nil`.  In Ruby, `nil == nil` is true
and therefore 

```ruby
(?a..).end == (5..).end
```

is also `true`, whereas 

```ruby
(?a..).end == (5..Float::INFINITY).end
```

is `false`.  Below is a more extended set of examples.

```ruby
(-Float::INFINITY..Float::INFINITY).size  # => Infinity
( Float::INFINITY..Float::INFINITY).size  # raises FloatDomainError
num1 = (5..Float::INFINITY)
num2 = (5..)
num1.end != num2.end  # => true
num1.size              # => Infinity
num2.size              # => Infinity

str1 = (?a..)
str1.end != num1.end   # => true
str1.end == num2.end   # => true (because both are nil)
str1.size              # => nil  (because Range#size is defined for Numeric only)
(..?z).size            # => Infinity  (contradicting the specification?)

(..3).to_s    => "..3"
(3..).to_s    => "3.."
(3..nil).to_s => "3.."
(nil..3).to_s => "..3"

(nil..) == (..nil)   # => true
(nil..) != (...nil)  # => true  (because exclude_end? differ)
"abcdef"[..nil]      # => "abcdef" (i.e., it is interpreted as (0..IntegerInfinity)
                     #    (n.b., nil.to_i==0; Integer(nil) #=> TypeError))
"abcdef"[..?a]       # raise: no implicit conversion of String into Integer (TypeError)
"abcdef"[0..100]     # => "abcdef"
"abcdef"[-100..100]  # => nil

(..nil).size   # => Float::INFINITY

(..nil).begin  # => nil
(..nil).first  # raise: cannot get the first element of beginless range (RangeError)
(..nil).last   # raise: cannot get the last element of endless range (RangeError)
(..nil).end    # => nil

(..nil).cover? 5    # => true
(..nil).cover? ?a   # => true
(..nil).cover? [?a] # => true
(..nil).cover? nil  # => true
```

For Integer,

```ruby
num1 = (5..Float::INFINITY)
num2 = (5..)
num1.end != num2.end  # => true (because (Float::INFINITY != nil))
num1.size              # => Float::INFINITY
num2.size              # => Float::INFINITY

(3...) == (3...nil)    # => true
(3..)  != (3...nil)    # => true  (because exclude_end? differ)

(3..).size   # => Float::INFINITY
(..3).begin  # => nil
(..3).first  # raise: cannot get the first element of beginless range (RangeError)
(3..).last   # raise: cannot get the last element of endless range (RangeError)
(3..).end    # => nil
(..3).each{} # raise: `each': can't iterate from NilClass (TypeError)
(..3).to_a   # raise: `each': can't iterate from NilClass (TypeError)
(3..).to_a   # raise: `to_a': cannot convert endless range to an array (RangeError)
(3..Float::INFINITY).to_a  # Infinite loop!

(-Float::INFINITY..4).first    # => -Float::INFINITY
(4..Float::INFINITY).last      # =>  Float::INFINITY
(-Float::INFINITY..4).first(2) # raise: can't iterate from Float (TypeError)
(4..Float::INFINITY).last(2)   # Infinite loop!
```

For String (or any user-defined class?),

```ruby
(?a..).end   == (5..).end   # => true (because both are nil)
(?a..).end   != (5..Float::INFINITY).end      # => true
(..?a).begin == (..5).begin # => true (because both are nil)
(..?a).begin != ((-Float::INFINITY)..5).begin # => true
(..?a).size  # => Float::INFINITY
(?a..).size  # => nil

(..?a).begin  # => nil
(..?a).first  # raise: cannot get the first element of beginless range (RangeError)
(?a..).last   # raise: cannot get the last element of endless range (RangeError)
(?a..).end    # => nil
(..?a).each{} # raise: `each': can't iterate from NilClass (TypeError)
(..?a).to_a   # raise: `each': can't iterate from NilClass (TypeError)
(?a..).to_a   # raise: `to_a': cannot convert endless range to an array (RangeError)
(?a..Float::INFINITY).to_a  # raise: bad value for range (ArgumentError)  # b/c it is not String!
```

### Comment on Range#size

The behaviour of `Range#size` is highly confusing. According to [Official doc](https://ruby-doc.org/core-3.1.2/Range.html#method-i-size),

```ruby
Returns the count of elements in self if both begin and end values are numeric;
otherwise, returns nil
```

But actually Ruby does not necessarily behaves in this way (see examples
above). In addition, the meaning of "elements" in the doc for general Numeric
is ambiguous. The following demonstrates it (reported as [Bug #18993](https://bugs.ruby-lang.org/issues/18993)):

```ruby
(5.quo(3)...5).size      # => 3
(5.quo(3).to_f...5).size # => 4
(5.quo(3)..5).size       # => 4
(5.quo(3).to_f..5).size  # => 4
```

### Comment on Range#count

The behaviour of `Range#count` is mostly understandable, but those of
borderless or with infinities are not trivial.

```ruby
(5..).count             # => Float::INFINITY
(..5).count             # => Float::INFINITY
(..nil).count           # => Float::INFINITY
(-Float::INFINITY..nil) # => Float::INFINITY
(-Float::INFINITY..Float::INFINITY).count  # raises (TypeError) "can't iterate from Float"
(..5).count(4)          # raises (TypeError)
(..5).count{|i| i<3}    # raises (TypeError)
(1..).count(4)          # infinite loop!
(1..).count{|i| i<3}    # infinite loop!
```

Basically, in some limited cases, the method returns Infinity, which are
special cases.

Given these, `RangeExtd::ALL.count` returns `Float::INFINITY` as another
special case.

## Install

```ruby
gem install range_extd
```

installs several files including

```ruby
range_extd.rb
range_extd/infinity.rb
```

in one of your `$LOAD_PATH` 

Alternatively get it from {http://rubygems.org/gems/range_extd}

Or, if you manually install it, place all the Ruby files under `lib/`
directory under one of your `RUBYLIB` directory paths, preserving the
directory structure. Note that `range_extd.rb` must be directly under the
library directory.

Then all you need to do is

```ruby
require "range_extd/load_all"
```

Or, if you only want minimum functions of this library, you can instead

```ruby
require "range_extd"
```

Basically, "`range_extd/load_all.rb`" is a wrapper Ruby file, which requires
the following files:

```ruby
require "range_extd"
require "range_extd/numeric"
require "range_extd/object"
require "range_extd/infinity"
require "range_extd/nowhere"
require "range_extd/range"
require "range_extd/nil_class"
```

Among these, the first three files are independent, whereas the last four
files are inseparable from the first one and are automatically require-d from
the first one.

The second and third files are a set of utility libraries; if your code
requires them, some methods are added or some existing methods are slightly
altered in the existing Ruby built-in classes: `Object` and `Numeric`
(including `Float` and `Integer`). How they are modified are
backward-compatible; simply a few new features are added.  Their use is highly
recommended; otherwise, the use of this library would be very limited.  For
example, the comparison operator `<=>` would not be commutative without them,
which might result in some nasty surprises.  For detail, refer to the
individual references.

Have fun!

## Simple Examples

In the following, I assume all the files are required.

### How to create a RangeExtd instance

Here are some simple examples.

```ruby
require "range_extd/load_all"
r = RangeExtd(?a...?d, true)  # => a<...d
r.exclude_begin?              # => true 
r.to_a                        # => ["b", "c"]
RangeExtd(1...2)            == (1...2)          # => true
RangeExtd(1, 2, false, true)== (1...2)          # => true
RangeExtd(1, 1, false, false)==(1..1)           # => true
RangeExtd(1, 1, true, true) == RangeExtd::NONE  # => true
RangeExtd(1, 1, false, true)  # => ArgumentError
(RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE) \
 == RangeExtd::ALL  # => true
```

`RangeExtd` provides three forms for initialization (hint: the first form is
probably the handiest with least typing and is the easiest to remember):

```ruby
RangeExtd(range, [exclude_begin=false, [exclude_end=false]])
RangeExtd(obj_begin, obj_end, [exclude_begin=false, [exclude_end=false]])
RangeExtd(obj_begin, string_form, obj_end, [exclude_begin=false, [exclude_end=false]])
```

The two parameters in the square-brackets specify the respective boundaries to
be excluded if true, or included if false (Default).  If they contradict the
first parameter of the range (`Range` or `RangeExtd`), the latter two
parameters have priorities. Alternatively, you can specify the same parameters
as the options `:exclude_begin` and `:exclude_end`, which have the highest
priority if specified. The `string_form` in the third form is like ".."
(including both ends) and "<..." (excluding both ends), set by users (see
{RangeExtd.middle_strings=}() for detail), and is arguably the most
visibly-recognisable way to specify any range with `exclude_begin=true`.

`RangeExtd.new()` is the same thing. For more detail and examples, see
{RangeExtd.initialize}.

### Slightly more advanced uses

```ruby
RangeExtd((0..), true).each do |i|
  print i
  break if i >= 9
end    # => self;  "123456789" => STDOUT
       # *NOT* "012..."
(nil..nil).valid?  # => true
(1...1).valid?     # => false
(1...1).null?      # => true
RangeExtd.valid?(1...1)              # => false
RangeExtd(1, 1, true, true).valid?   # => true
RangeExtd(1, 1, true, true).empty?   # => true
RangeExtd(?a, ?b, true, true).to_a?  # => []
RangeExtd(?a, ?b, true, true).null?  # => true  (empty? is same in this case)
RangeExtd(?a, ?e, true, true).to_a?  # => ["b", "c", "d"]
RangeExtd(?a, ?e, true, true).null?  # => false
RangeExtd::NONE.is_none?             # => true
RangeExtd(1...1, true) == RangeExtd::NONE # => true
RangeExtd::ALL.is_all?               # => true
(nil..nil).is_all?                   # => false
(-Float::INFINITY..Float::INFINITY).is_all?    # => false
(nil..nil).equiv_all?                # => true
(-Float::INFINITY..Float::INFINITY).equiv_all? # => true
(3...7).equiv?(3..6)    # => true
(nil..nil).equiv?(RangeExtd::ALL)    # => true
```

All the methods that are in the built-in Range can be used in {RangeExtd},
which is a child class of {Range}.

## Description

Once the file `range_extd.rb` is required, the three classes are defined:

*   RangeExtd
*   RangeExtd::Infinity
*   RangeExtd::Nowhere


Also, several methods are added or altered in {Range} class and {NilClass}.
All the changes made in them are backward-compatible with the original.

Note that whereas the changes in {Range} could be in principle separable from
{RangeExtd}, if no one would likely want to use them separately, those in
{NilClass} are unavoidable.  Without them, {RangeExtd::NONE} could not be
defined, for `ArgumentError` (bad value for range) would be raised in the
initialization due to the way Ruby built-in Range is implemented.

See [discussion at Stackoverflow](https://stackoverflow.com/a/14449380/3577922).

### RangeExtd::Infinity Class

Class {RangeExtd::Infinity} has only two constant instances.

*   RangeExtd::Infinity::NEGATIVE
*   RangeExtd::Infinity::POSITIVE


They are the objects that generalize the concept of `Float::INFINITY`  to any
Comparable objects.  The methods `<=>` are defined.

You can use them in the same way as other objects, such as,

```ruby
(RangeExtd::Infinity::NEGATIVE.."k")
```

However, since they do not have any other methods, the use of them out of
Range or its sub-classes is probably meaningless.

Note for any Numeric object, you probably would like to use `Float::INFINITY`
instead in principle.

Any objects in any user-defined Comparable class are commutatively comparable
with those two constants, as long as the cmp method of the class is written in
the **standard** way, that is, delegating the cmp method to the parent class,
ultimately `Object`, when they encounter an object of a class they don't know.

For more detail, see the document at [RubyGems webpage](http://rubygems.org/gems/range_extd), which is generated from the
source-code annotation with YARD.

### RangeExtd::Nowhere Class

Class {RangeExtd::Nowhere} is a Singleton class, which mimics {NilClass}. The
sole instance is available as

*   RangeExtd::Nowhere::NOWHERE


This instance returns, for example, true for `nil?` and the same object-ID for
`object_id` as `nil` and equal (`==`) to nil.  It is used to constitute
{RangeExtd::NONE}.

It is not, however, recognised as the false value in conditional statements.

Also, a Range containing {RangeExtd::Nowhere::NOWHERE} is **not** "valid" as a
Range (see below), except for {RangeExtd::NONE}.

### RangeExtd Class

{RangeExtd} objects are immutable, the same as {Range}. Hence once an instance
has been created, it would not change.

How to create an instance is explained above (in the Examples sections).  Any
attempt to try to create an instance of {RangeExtd} that is not "valid" as a
range (see below) raises an exception (`ArgumentError`), and fails.

There are two constants defined in this class:

*   RangeExtd::NONE
*   RangeExtd::ALL


The former represents the empty range and the latter does the range that
covers everything, namely open-ended for the both negative and positive
directions.

In addition to all the standard methods of {Range}, the following methods are
added to both {RangeExtd} and {Range} classes. See the document of each method
for detail (some are defined only in {Range} class, as {RangeExtd} inherits
it).

*   `exclude_begin?` (not defined in {Range} class)
*   `valid?` 
*   `empty?` 
*   `null?` 
*   `is_none?`
*   `is_all?` 
*   `equiv?` 


There are three class methods, the first of which is equivalent  to the
instance method `valid?`:

*   `RangeExtd.valid?` 
*   `RangeExtd.middle_strings=(ary)` 
*   `RangeExtd.middle_strings` 


#### Details about validity, emptiness, and nullness

What is valid (`#valid?` => true) as a range is defined as follows.

1.  Both `begin` and `end` elements must be Comparable to each other, and the
    comparison results must be consistent between the two. The three
    exceptions are {RangeExtd::NONE} and Beginless and Endless Ranges
    (introduced in Ruby 2.7 and 2.6, respectively), which are all valid. 
    Accordingly, `(nil..nil)` is valid in {RangeExtd} Ver.2.0+ (nb., it used
    to raise Exception in Ruby 1.8).
2.  Except for {RangeExtd::NONE} and Beginless Range, the object of
    `Range#begin` must have the method `<=`. Therefore, some Endless Ranges
    (Ruby 2.6 and later) like `(true..)` are **not** valid. Note even "`true`"
    has the method `<=>` and hence checking `<=` is essential.
3.  Similarly, except for {RangeExtd::NONE} and Endless Range, `Range#end`
    must have the method `<=`. Therefore, some Beginless Ranges (Ruby 2.7 and
    later) like `(..true)` are **not** valid.
4.  **begin** must be smaller than or equal (`==`) to **end**, that is,
    `(begin <=> end)` must be either -1 or 0.
5.  If **begin** is equal to **end**, namely, `(begin <=> end) == 0`, the
    exclude status of the both ends must agree, except for the cases where
    both `begin` and `end` are `nil` (beginless and endless Range). In other
    words, if the `begin` is excluded, `end` must be also excluded, and vice
    versa. For example, `(1...1)` is NOT valid for this reason, because any
    built-in Range object has the exclude status of `false` (namely,
    inclusive) for `begin`, whereas `RangeExtd(1...1, true)` is valid and
    equal (`==`) to {RangeExtd::NONE}.
6.  Range containing {RangeExtd::Nowhere::NOWHERE} except for
    {RangeExtd::NONE} is **not** valid.


For more detail and examples, see the documents of {RangeExtd.valid?} and
{Range#valid?} 

The definition of what is empty ({Range#empty?} == `true`) as a range is as
follows;

1.  the range must be valid: `valid?` => true
2.  if the range id discrete, that is, `begin` has the `succ` method, there
    must be no member within the range (which means the begin must be
    excluded, too):  `to_a.empty?` => true
3.  if the range is continuous, that is, begin does not have the `succ`
    method, `begin` and `end` must be equal (`(begin <=> end) == 0`) and both
    the boundaries must be excluded: `(exclude_begin? && exclude_end?)` =>
    true.


Note that ranges with equal `begin` and `end` with inconsistent two exclude
status are not valid, as mentioned in the previous paragraph. The built-in
Range always has the begin-exclude status of `false`.  For that reason, no
instances of built-in Range  have the status of `empty?` of `true`.

For more detail and examples see the documents of {Range#empty?} 

Finally, {Range#null?} is equivalent to "either empty or not valid".
Therefore, for RangeExtd objects `null?` is equivalent to `empty?`.  In most
practical cases, {Range#null?} will be perhaps more useful than
{Range#empty?}.

In comparison (`<=>`) between a RangeExtd and another RangeExtd or Range
object, these definitions are taken into account. Some of them are shown in
the above Examples section. For more detail, see {Range#<=>} and
{RangeExtd#<=>}.

Note that as long as the operation is within Range objects, the behaviour is
identical to the standard Ruby -- it is completely backward-compatible. 
Therefore, requiring this library should not affect any existing code in
principle.

#### equality

The method `eql?` checks the equality of the hash values according to Ruby's
specification and hence every parameter must agree. By contrast, `==` makes a
more rough comparison and if the two objects are broadly the same, returns
`true`.

```ruby
RaE(0...0, true) == RaE(?a...?a, true)  # => false
RaE(0...1, true) == RaE(5...6, true)    # => true
```

## Known bugs

*   Although {RangeExtd::Nowhere::NOWHERE} cannot be used in the context of 
    {RangeExtd} (because it is not {Range#valid?}), users could still use it
    within just the built-in Range framework. Perhaps,
    {RangeExtd::Nowhere::NOWHERE} should be redefined as a non-nil object?
*   This library of Version 2+ does not work in Ruby 2.6 or earlier.
*   This library of Version 1 does not work in Ruby 1.8 or earlier. For Ruby
    1.9.3 it is probably all right, though I have never tested it.
*   Some unusual (rare) boundary conditions are found to vary from version to
    version in Ruby, such as an implementation of `Hash#=>`. Though the test
    scripts are pretty extensive, they have not been performed over many
    different versions of Ruby. Hence, some features may not work well in some
    particular versions, although such cases should be very rare.
*   {RangeExtd#hash} method does not theoretically guarantee to return a
    unique number for a {RangeExtd} object, though to encounter a hash number
    that is used elsewhere is extremely unlikely to happen in reality.
*   `RangeExtd::NONE.inspect` and `RangeExtd::NONE.to_s` return
    "Null<...Null", but it is displayed as "nil...nil" in Ruby `irb` and hence
    it is not easily recognizable in `irb`.


Extensive tests have been performed, as included in the package.

## ToDo

*   If {RangeExtd::Infinity::POSITIVE} (and NEGATIVE) behaves like `nil` (in
    the same way as {RangeExtd::Nowhere::NOWHERE}, it may be useful. However,
    a range containing such objects would not work with String like
    `"abcde"[my_nil..]`, for it seems the String class makes a pretty rigorous
    check about `nil`.  So, I guess the practical applicability would not be
    improved so much, as far as the built-in Ruby classes are concerned.
*   A method like "`similar`" may be useful. For example,
    `(-Float::INFINITY..Float::INFINITY)` and
    `(-Float::INFINITYnil...Float::INFINITY)` have no mathematical difference,
    because excluding an infinity is meaningless. Indeed it makes no
    difference in the results of operations with non-infinite Range/Rangeary.


## History memo

*   `((?a..?z) === "cc")` would give false with Ruby 2.6.x or earlier, but
    true if later.
*   `(Float::INFINITY..Float::INFINITY).size` used to return 0 (in Ruby-2.1 at
    least) but raises `FloatDomainError: NaN` as of Ruby-2.6 and later,
    including Ruby 3. I do not know in which version the behaviour changed.


### RangeExtd Ver.2

*   The paths for the libraries are moved up by one directory in {RangeExtd}
    Ver.2 from Ver.1 in order that their locations follow the Ruby Gems
    convention.
*   Compatible with Beginless Range introduced in Ruby-2.7.
*   `RangeExtd::Infinity#succ` is now undefined, in line with Float.
*   Extensions for `Object` and `Numeric` are not in default anymore and are
    optional.
*   `RangeExtd#eql?` follows the Ruby default behaviour (comparison based on
    [#hash]), eliminating special cases in comparison with {RangeExtd::NONE}.
*   Fixed a bug where `RangeExtd#min_by` (and `max_by` and `minmax_by`) did
    not work correctly.


### RangeExtd Ver.1.1

As of Ver.1.1, the `RangeExtd::Infinity` class instances are not comparable
with `Float::INFINITY`; for example,

```ruby
RangeExtd::Infinity::POSITIVE != Float::INFINITY  # => true
```

Conceptionally, the former is a generalized object of the latter and hence
they should not be **equal**.  See the reference of {RangeExtd::Infinity} for
detail.  Note, the behaviour of Endless Range from Ruby 2.6 may feel a little
odd, as follows:

```ruby
num1 = (5..Float::INFINITY)
num2 = (5..)
num1.end != num2.end  # => true
num1.size              # => Infinity
num2.size              # => Infinity

str1 = (?a..)
str1.end == num2.end   # => true (because both are nil)
str1.size              # => nil
```

### RangeExtd Ver.1.0

`RangeExtd::Infinity::POSITIVE` is practically the same as [Endless Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
introduced in Ruby 2.6 released in 2018 December!!  In other words, the
official Ruby has finally implement a part of this library! However,
`RangeExtd::Infinity::NEGATIVE` was not yet implemented (at the time) in the
official Ruby Range (it has no "boundless begin").

## Final notes

All the behaviours within RangeExtd (not Range), such as any comparison
between two RangeExtd, should be (or hopefully?) natural for you.  At least it
is well-defined and self-consistent, as the logical structure of the ranges is
now complete with {RangeExtd}.

In this section in the earlier versions, I wrote:

> Note that some behaviours for open-ended or begin-excluded ranges may give
you a little shock at first.  For example, the method `member?(obj)` for an
open-ended range for the negative direction with discrete elements returns
`nil`.  That is because no meaningful method of `succ()` is defined for the
(negative) infinity, hence it is theoretically impossible in general to check
whether the given obj is a member of the range or not.  You may find it to be
weird, but that just means the concept of the infinity is unfamiliar to us
mortals!

Now, interestingly, the introduction of "beginless Range" in Ruby means every
Ruby programmer must be familiar with the concept! I would call it a progress.

Still, comparisons between RangeExtd and Range may give you occasional
surprises.  This is because some of the accepted ranges by built-in Range
class are no longer valid in this framework with the inclusion of
exclude-status of the begin boundary, as explained. Hopefully you will feel it
natural as you get accustomed to it. And I bet once you have got accustomed to
it, you will never want to go back to the messy world of logical
incompleteness, that is, the current behaviour of Range!

Enjoy.

## Copyright etc

<dl>
<dt>Author</dt>
<dd>   Masa Sakano &lt; info a_t wisebabel dot com &gt;</dd>
<dt>License</dt>
<dd>   MIT.</dd>
<dt>Warranty</dt>
<dd>   No warranty whatsoever.</dd>
<dt>Versions</dt>
<dd>   The versions of this package follow Semantic Versioning (2.0.0)
    http://semver.org/</dd>
</dl>



---

# RangeExtd - 拡張Rangeクラス - exclude_begin と無限大に開いた範囲と

## はじめに

このパッケージは、Range を拡張した RangeExtd クラスを定義しています。 以下の特徴を持ちます。

1.  メソッド exclude_begin? の導入 (レンジの始点を除外できる),
2.  (無限大に)開いたレンジ(`nil`のように*未定義*のレンジではない)
3.  NONE (空レンジ) と ALL (全範囲レンジ)定数の導入
4.  Rubyで初めて自己論理的に完結したレンジ構造の達成
5.  組込Rangeとの完全後方互換性


組込Rangeにある exclude_end に加えて、exclude_beginを導入したこと、及
び無限大へ開いた範囲を許可したことで、一次元上の範囲の論理的完全性を実 現しました。

このライブラリの最大の利点は、FloatやRationalのような数で応用場面の多 い複数レンジの論理演算が可能になったことです。 Gem
[Rangeary](https://rubygems.org/gems/rangeary) は本ライブラリをフ
ルに用いて、レンジの論理演算の概念を実現しています。そのためには、無限 に開いた可能性がありまた始端と終端のいずれもが除外されている可能性がある
レンジの概念が不可欠でした。たとえば、 レンジ `(?a..?d)` の否定(あるいは補集合)が2つのレンジ
`(-"Infinity-Character"...3)` と `(?d(exclusive).."Infinity-Character")`
であり、その否定が元の `(?a..?d)` になります。このような演算は、本 `RangeExtd` クラスを用いる ことで初めて可能になります。

Rangeary: {https://rubygems.org/gems/rangeary}

組込 Rangeは大変有用なクラスであり、Rubyユーザーに容易なプログラミングを可能にす
るツールでした。しかし、始点を除外することができないのが玉に瑕でありました。

ただし、それにはれっきとした理由があることは分かります。Rubyの Rangeは、Numeric
(厳密にはその実数を表現したもの)だけに限ったものではありません。 `succ()` メソッ ドを持つオブジェクトによる
Rangeは極めて有用です。一方、`succ()` の逆に相 当するメソッドは一般的には定義されていません。そういう意味で、Rangeは本質的に非
対称です。加えて、よく使われる Rangeオブジェクトのうちあるもの(たとえば Float)は 連続的なのに対し、そうでないものも普通です(たとえば
Integer や String)。この状況 が厳密な定義をする時の混乱に拍車をかけています。

ここで始点を除外可能としたことは、そういう意味で、道筋が100パーセント明らかなも のではありませんでした。ここで私が採用した
{RangeExtd}クラスの定義は、おそらく、考え られる唯一のものではないでしょう。とはいえ、個人的には満足のいくものに仕上がりま
したし、このレンジという枠内での論理的完全性をうまく達成できたと思います。

このクラスが少なからぬ人に有用なものであることを願ってここにリリースします。

### Rangeの正当性

Rubyの組込みRangeは、メンバーに許されるものに対してとても慣用です。た とえば、`(true...true)`
は、それが何を意味するのかはともかく、完全に正 当なRangeです。もっとも、イテレーターを伴う`each`や`to_a` といったメソッ
ドを使おうとすると例外(`TypeError`)が発生ますし、利用価値はごく限られ るでしょうが。

本ライブラリにより、Rangeの「正当性」が厳密に定義されます。本ライブラ リは、Rangeクラスに{Range#valid?},
{Range#null?} and {Range#empty?}を はじめとするいつくつかのメソッドを追加します。それらはもちろん、すべて
の子クラスにも継承されます。

一例として、 `(3...3).valid?` は偽(false)を返します。なぜならば、
要素3は始端では含まれるのに終端では除外されているため、相互に矛盾してい るからです。このRangeExtd クラスでは、次の2つが正当なレンジと見做され
ます。

```ruby
* RangeExtd.new(3, 3, true,  true)   # => an empty range
* RangeExtd.new(3, 3, false, false)  # => a single-point range (3..3)
```

ただし、もし組込みRangeに閉じて使う限りは、何も変わりません。つまり、 標準Rubyと完全に互換性を保っています。

### 無限に開いたレンジ

Ruby 2.6 と 2.7 でそれぞれ終端および始端のないRangeが導入されました。
これら境界のないRangeと本ライブラリの無限に開いたRangeとの違いは 少々難解で、現実の場面で実用的というよりは、概念的哲学的なものといって
いいでしょう(詳しくは「背景」の章を参照)。しかし、気にすることはありま せん。実用という意味では、両者は互換であり、それほど気を遣うことはあり
ません。端的には、特に不満がない限りは、組込みの境界のないRangeを使え ばよいでしょう。

無限に開いたレンジを表すのは以下のようにします。{RangeExtd::Infinity}クラスで
定義されている二つの定数(無限大または無現小、あるいは無限前と無限後)の いずれかを用います。

*   RangeExtd::Infinity::NEGATIVE
*   RangeExtd::Infinity::POSITIVE


これらは基本的に `Float::INFINITY` を全ての Comparable であるオブジェクトに*一般化*したものです。たとえば、

```ruby
("a"..RangeExtd::Infinity::POSITIVE).each
```

は、"a"から始まる `String#succ` を使った無限のイテレーターを与えます (だから、どこかで必ず
breakするようにコードを書きましょう!)。 この例の場合、Ruby-2.6以上の以下とまったく同じように動きます。

```ruby
("a"..).each
```

### News: Libraryの場所他

**重要**: ライブラリのパスが{RangeExtd} Ver.1 から Ver.2 で、 ディレクトリの階層一つ上がりました。これは、Ruby
Gemの慣用にそうように するためです。端的には、標準的方法は、`require "range_extd"` です。
以前のパスは、"range_extd/range_extd" でした。

それに伴い、{RangeExtd} のバージョンを2.0にあげました。

以下が、その主な変更点です。詳しくは、「履歴メモ」章を参照ください。

#### News: Beginless Range サポートしました

Ruby 2.7 で始端のない [Beginless range](https://rubyreferences.github.io/rubychanges/2.7.html#beginless-range)
がサポートされました。 `RangeExtd` も今やサポートします。この影響で、仕様に重要な変更があります。

まず、{RangeExtd::NONE} は、事実上
`RangeExtd((RangeExtd::Nowhere::NOWHERE...RangeExtd::Nowhere::NOWHERE), true)`
になりました。すなわち、両端が {RangeExtd::Nowhere::NOWHERE} であり、 両端({RangeExtd#begin} と
{RangeExtd#end})とも除外されています。 以前のバージョンでは、{RangeExtd::NONE} の両端は `nil` でした。 Range
`(nil..nil)` は、Ruby-2.6 およびそれ以前ではそもそも許されていな
くて、そのために{RangeExtd::NONE}に独特な表記として幸便だったものです。 しかし、Ruby-2.7 以降では nil から nil
のRangeが許容されます。つまり、 `(nil..nil)` は完全に正当であり、それは {RangeExtd::NONE} を表していた
`RangeExtd((nil...nil), true)` と事実上同じになってしまいます。前者は、
後者とはまったく異なるオブジェクトであり、(除外フラグをのぞけば)むしろ {RangeExtd::ALL}
に極めて近いにも拘らずです。だから、変更が必要になったのです。

もっとも、この変更は概念的なものであり、ユーザー視点ではほぼ変更は見えません。 {RangeExtd::NONE}の始端と終端である
{RangeExtd::Nowhere::NOWHERE} は、 {NilClass} とほぼまったく同じように振る舞います(以下の「詳説」章を参照)。
{RangeExtd} Ver.1以前でその値はまさに `nil` だったことを考えれば、
Ver.2で{RangeExtd::Nowhere::NOWHERE} が{RangeExtd::NONE}
に使われるようになったと言っても、今まで動いていたコードには何の変更も必要ないはずです。 オブジェクトが{RangeExtd::NONE}
かどうかをチェックする推奨方法は、 今までもずっとそうだったように、{RangeExtd#is_none?} です
(`Enumerable#none?`とは異なるのでご注意)。実用的には、 {Range#null?} がユーザーが希望する挙動であることが大半でしょう
(注: `(true..true).null?` は偽(`false`)を返すことに注意。 本マニュアルの「詳説」章の「RangeExtd
Class」を参照)。

次に、`RangeExtd.valid?(nil..)` は、真(`true`)を返すようになりました。 以前は、偽を返していました。そしてそれは
{RangeExtd::ALL} に等しいです。

[たとえば、`"abc"](nil..)` は以前のバージョンでは不正もしくは文法エラー
さえ出ていましたが、Ruby-2.7以降では完全に正当なRuby表現です。 したがって、もし仮に`RangeExtd`
がそれらを正当でないと見做したならば、 不自然に受け取られるでしょう。

`RangeExtd.valid?(true..)` は、依然 `false` を返します。

他の大きな変更には以下があります。

*   `RangeExtd::Infinity#succ` はFloatクラスに合わせて未定義になりました。
*   `Object` と `Numeric` クラスの拡張はデフォルトではなく、オプション(ユーザーの選択)となりました。
*   `RangeExtd#eql?`
    [はRubyの標準(](#hash)値を比較)にそうようにし、今まであった{RangeExtd::NONE}との特別な比較ルーチンを削除しました。
*   `RangeExtd#min_by` (`max_by` と `minmax_by`) のバグを修正しました。


#### News: Endless Range サポートしました

2019年10月より、本パッケージは、Ruby 2.6 で導入された [Endless Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
(終端のない Range)を正式サポートしました。よって、Version 1.0 をリリースしました!

Ruby 2.7 では、[Beginless range](https://rubyreferences.github.io/rubychanges/2.7.html#beginless-range)
が導入されました.

#### 注: Rangesmallerとの関係

このパッケージは、(今やサポートされていない) [Rangesmaller](https://rubygems.org/gems/rangesmaller)
パッケージ及びクラスを 後継するものです。同クラスの機能に、無限に開いた範囲を許す機能が加わり、また、オ
ブジェクト生成時のインターフェースが変更されています。 {https://rubygems.org/gems/rangesmaller}

## 背景

### Endless Range と Beginless Range

[Endless Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
(終端のないRange)と [Beginless Range](https://rubyreferences.github.io/rubychanges/2.7.html#beginless-range)
(始端のないRange)はそれぞれ 2018年12月および2019年12月リリースの Ruby 2.6 と 2.7 で導入されました。

そのおかげで、Rubyの組込み`Range` は、`RangeExtd` が提供していた機能の いくつかを持つようになりました。
ただし、今でも、明快なものも微妙なものも含めていくつかの違いがあります。

本ライブラリのはっきりとした利点は、`exclude_begin?` (つまり始端を除外する)機能です。

境界のないRangeについては、本ライブラリが提供するものは、一言で言えば、 抽象的な意味で無限に開いたレンジです。
概念的な主な違いは、Rubyの組込み`Range` は*未定義*の境界を表すのに対し、 `RangeExtd` は*無限に開いた*境界を表します。

この違いは微妙ながら、はっきりとした意味があります。 以下に、標準Rubyの特にNumericのRangeを例示します。というのも、Numeric
はこの両方を提供しているために、違いがわかりやすいのです。

```ruby
"abcdef"[..2]   # => "abc"
"abcdef"[..2.0] # => "abc"
"abcdef"[(-Float::INFINITY)..2]  # raise (RangeError)
"abcdef"[(-1)..2] # => ""
"abcdef"[(-6)..2] # => "abc"
"abcdef"[(-7)..2] # => nil
(-Float::INFINITY..5).first(1) # raise: can't iterate from Float (TypeError)
(-Float::INFINITY..5).first    # => -Infinity
(-Float::INFINITY..5).begin    # => -Infinity
(..5).first   # raise: cannot get the first element of beginless range (RangeError)
(..5).begin   # => nil
```

最初、そして2番目の式に出てくるのが始端のないRangeで、始端が未定義です。 Stringクラスは、その「始点の値」を0だと*解釈*しています。
対照的に、3番目の式では、例外が発生しています。この仕様は、 始点の値が定義されていて、でも負の無限大だから、と考えれば、理解できます。
実際、Stringの場合、負の数の添字は、(4番目、6番目の例にあるように) 特別な意味を持っていますからね。

最後の5つの例は、興味深いです。 `Range#begin` は単純に始点の値を返します。 `Range#first`
は引数が与えられなければ、最初の「要素」を返します。 `(Float::INFINITY..5)` には最初の要素があるため、それが返されます。
しかしbeginless {Range} では話が異なります。定義された最初の要素がないため、 `Range#first` は、`RangeError`
例外を発生させます。対照的に、 引数 `n` が `Range#first` に与えられた時は、`n`個の要素を持つ配列
(Array)が返されなければなりません。Floatから値を数えるのは未定義であるため、 負の無限大からのRangeの場合は、`TypeError`
例外が発生します。 筋が通っていると思いませんか?

ところで、補足すると、`(5..8.6).last(2)` は正当であって配列 `[7, 8]` を返します。また、`(2.2..8.6).size`
も(なぜか?)正当です。混乱しますね……。

別のポイントとして、無限大には明快な数学的定義がありますが、 すべてのRangeがそれを認めるわけではありません。たとえば、
自作クラスで、アルファベット小文字1文字だけを持ち、 Stringクラスと同様にRangeが定義できる例を考えてみます。
すると、最小の始端と最大の終端は、それぞれ"`a`"と"`z`"です。 この場合、「無限大」(あるいは無限小)とは何を意味するでしょうか?
厳密な意味では、それは不正とすべきでしょうか。あるいは、 この場合の無限大は"`z`"を表す数と解釈すべきでしょうか? それとも別のなにか?

概念としては、包括的な解釈のほうが便利です。実際、 [Rangeary](https://rubygems.org/gems/rangeary)
ライブラリは、 `RangeExtd` をそのように利用しています。すなわち、 Range の「否定」(補集合)を積極的に用いて、複数Ranges
の論理演算を実現しています。しかし、 すべてのアプリケーションにそう解釈することを強要することはできません。

まとめると、*未定義*境界は定義上未定義であり、その解釈はアプリケーション任せになるのに対し、
正負の無限大境界は明快な定義はあるかも知れないけれど、実際の応用では柔軟な解釈が望ましい場合もあるかもしれない、 というところです。

これらを考慮し、本ライブラリの {RangeExtd::Infinity::NEGATIVE} と
{RangeExtd::Infinity::POSITIVE} とは、事実上 `nil` のように振る舞うようにデザインされています。ただし、
ユーザーが別扱いすることは可能です。

### endless and beginless Rangesの振舞い

組込み Endless/Beginless Range の振舞いは幾分混乱するところがあります。 加えて、`Range#size`にはバグが複数あるようです
([Bug #18983](https://bugs.ruby-lang.org/issues/18983) と
    {Bug #18993}[https://bugs.ruby-lang.org/issues/18993])。

少なくとも、公式マニュアルに記載されている仕様とは矛盾する振舞いがあり、 混乱に拍車をかけます。

Rubyの実装では、beginless/endless Rangesの始端と終端の値は、 `nil` と解釈されます。 Rubyでは `nil == nil` が真であるために、

```ruby
(?a..).end == (5..).end
```

も真です。一方、

```ruby
(?a..).end == (5..Float::INFINITY).end
```

は偽(`false`)です。以下が幅広い例です。

```ruby
(-Float::INFINITY..Float::INFINITY).size  # => Infinity
( Float::INFINITY..Float::INFINITY).size  # raises FloatDomainError
num1 = (5..Float::INFINITY)
num2 = (5..)
num1.end != num2.end  # => true
num1.size              # => Infinity
num2.size              # => Infinity

str1 = (?a..)
str1.end != num1.end   # => true
str1.end == num2.end   # => true (because both are nil)
str1.size              # => nil  (because Range#size is defined for Numeric only)
(..?z).size            # => Infinity  (contradicting the specificatin?)

(..3).to_s    => "..3"
(3..).to_s    => "3.."
(3..nil).to_s => "3.."
(nil..3).to_s => "..3"

(nil..) == (..nil)   # => true
(nil..) != (...nil)  # => true  (because exclude_end? differ)
"abcdef"[..nil]      # => "abcdef" (i.e., it is interpreted as (0..IntegerInfinity)
                     #    (n.b., nil.to_i==0; Integer(nil) #=> TypeError))
"abcdef"[..?a]       # raise: no implicit conversion of String into Integer (TypeError)
"abcdef"[0..100]     # => "abcdef"
"abcdef"[-100..100]  # => nil

(..nil).size   # => Float::INFINITY

(..nil).begin  # => nil
(..nil).first  # raise: cannot get the first element of beginless range (RangeError)
(..nil).last   # raise: cannot get the last element of endless range (RangeError)
(..nil).end    # => nil

(..nil).cover? 5    # => true
(..nil).cover? ?a   # => true
(..nil).cover? [?a] # => true
(..nil).cover? nil  # => true
```

Integerクラスならば、

```ruby
num1 = (5..Float::INFINITY)
num2 = (5..)
num1.end != num2.end  # => true (because (Float::INFINITY != nil))
num1.size              # => Float::INFINITY
num2.size              # => Float::INFINITY

(3...) == (3...nil)    # => true
(3..)  != (3...nil)    # => true  (because exclude_end? differ)

(3..).size   # => Float::INFINITY
(..3).begin  # => nil
(..3).first  # raise: cannot get the first element of beginless range (RangeError)
(3..).last   # raise: cannot get the last element of endless range (RangeError)
(3..).end    # => nil
(..3).each{} # raise: `each': can't iterate from NilClass (TypeError)
(..3).to_a   # raise: `each': can't iterate from NilClass (TypeError)
(3..).to_a   # raise: `to_a': cannot convert endless range to an array (RangeError)
(3..Float::INFINITY).to_a  # Infinite loop!

(-Float::INFINITY..4).first    # => -Float::INFINITY
(4..Float::INFINITY).last      # =>  Float::INFINITY
(-Float::INFINITY..4).first(2) # raise: can't iterate from Float (TypeError)
(4..Float::INFINITY).last(2)   # Infinite loop!
```

Stringクラス(あるいはユーザー定義クラス?)ならば、

```ruby
(?a..).end   == (5..).end   # => true (because both are nil)
(?a..).end   != (5..Float::INFINITY).end      # => true
(..?a).begin == (..5).begin # => true (because both are nil)
(..?a).begin != ((-Float::INFINITY)..5).begin # => true
(..?a).size  # => Float::INFINITY
(?a..).size  # => nil

(..?a).begin  # => nil
(..?a).first  # raise: cannot get the first element of beginless range (RangeError)
(?a..).last   # raise: cannot get the last element of endless range (RangeError)
(?a..).end    # => nil
(..?a).each{} # raise: `each': can't iterate from NilClass (TypeError)
(..?a).to_a   # raise: `each': can't iterate from NilClass (TypeError)
(?a..).to_a   # raise: `to_a': cannot convert endless range to an array (RangeError)
(?a..Float::INFINITY).to_a  # raise: bad value for range (ArgumentError)  # b/c it is not String!
```

### Range#size についての注記

`Range#size` の振舞いはとてもわかりにくいです。
[公式マニュアル](https://ruby-doc.org/core-3.1.2/Range.html#method-i-size) によれば、

```ruby
Returns the count of elements in self if both begin and end values are numeric;
otherwise, returns nil
```

しかし、実際のRubyの挙動は必ずしもこの通りではありません(上述の例参照)。 加えて、一般のNumeric
に対して"elements"が一体何かは不明瞭です。 だから、Stringならば必ずnilが買える 以下が一例です([Bug #18993](https://bugs.ruby-lang.org/issues/18993) として報告済):

```ruby
(5.quo(3)...5).size      # => 3
(5.quo(3).to_f...5).size # => 4
(5.quo(3)..5).size       # => 4
(5.quo(3).to_f..5).size  # => 4
```

### Range#count についての注記

`Range#count` の振舞いの大半は理解できます。しかし、 境界のないものや無限大関係は自明ではありません。

```ruby
(5..).count             # => Float::INFINITY
(..5).count             # => Float::INFINITY
(..nil).count           # => Float::INFINITY
(-Float::INFINITY..nil) # => Float::INFINITY
(-Float::INFINITY..Float::INFINITY).count  # raises (TypeError) "can't iterate from Float"
(..5).count(4)          # raises (TypeError)
(..5).count{|i| i<3}    # raises (TypeError)
(1..).count(4)          # infinite loop!
(1..).count{|i| i<3}    # infinite loop!
```

端的には、一部の特別なケースについては、同メソッドは Infinity (無限大)を返します。

これを考慮して本ライブラリの`RangeExtd::ALL.count` は、特別なケースとして、 returns `Float::INFINITY`
を返します。

## インストール

```ruby
gem install range_extd
```

により、

```ruby
range_extd.rb
range_extd/infinity.rb
```

をはじめとした数個のファイルが`$LOAD_PATH` の一カ所にインストールされるはずです。

あるいは、パッケージを{http://rubygems.org/gems/range_extd}から入手できます。

後は、Ruby のコード(又は irb)から

```ruby
require "range_extd/load_all"
```

とするだけです。もしくは、本ライブラリのの最小限セットだけ使う場合は、

```ruby
require "range_extd"
```

でもいいです。 端的には "`range_extd/load_all.rb`" は、ラッパーであり、以下のファイルを読み込みます:

```ruby
require "range_extd"
require "range_extd/numeric"
require "range_extd/object"
require "range_extd/infinity"
require "range_extd/nowhere"
require "range_extd/range"
require "range_extd/nil_class"
```

このうち、最初の3つは独立で、下の4つは一番上のファイルと必ず一緒に使われるもので、最初のファイルを読めば自動的に読み込まれます。

2番目と3番目のファイルは、ユーティリティライブラリです。読み込めば、 Ruby組込みクラスの `Object` と `Numeric` (`Float`
と `Integer`を含む) にいくつかのメソッドが追加されたり機能が追加されます。
追加された機能はすべて後方互換であり、単に既存のクラスに機能を追加するだけです。 これらの読み込みを強く推奨します。もし読み込まない場合は、本ライブラリ
のパワーがごく限られてしまいます。たとえば、比較演算子`<=>` が可換でないため、驚くような挙動になることがあるでしょう。
具体的な追加機能はそれぞれのマニュアルを参照ください。

## 単純な使用例

以下の例では、ライブラリのすべてのファイルが読み込まれている(require) と仮定します。

### RangeExtd インスタンスを作成する方法

以下に幾つかの基本的な使用例を列挙します。

```ruby
require "range_extd/load_all"
r = RangeExtd(?a...?d, true)  # => a<...d
r.exclude_begin?              # => true 
r.to_a                        # => ["b", "c"]
RangeExtd(1...2)            == (1...2)          # => true
RangeExtd(1, 2, false, true)== (1...2)          # => true
RangeExtd(1, 1, false, false)==(1..1)           # => true
RangeExtd(1, 1, true, true) == RangeExtd::NONE  # => true
RangeExtd(1, 1, false, true)  # => ArgumentError
(RangeExtd::Infinity::NEGATIVE..RangeExtd::Infinity::POSITIVE) \
 == RangeExtd::ALL  # => true
```

`RangeExtd` のインスタンスを作成する方法が3通りあります(おそらく 最初のやり方が最も単純でタイプ量が少なく、かつ覚えやすいでしょう)。

```ruby
RangeExtd(range, [exclude_begin=false, [exclude_end=false]], opts)
RangeExtd(obj_begin, obj_end, [exclude_begin=false, [exclude_end=false]], opts)
RangeExtd(obj_begin, string_form, obj_end, [exclude_begin=false, [exclude_end=false]], opts)
```

大括弧の中の二つのパラメーターが、それぞれ始点と終点とを除外する(true)、または含む
(false)を指示します。もし、その二つのパラメーターが最初のパラメーターのレンジ (`Range` または `RangeExtd`)
と矛盾する場合は、ここで与えた二つのパラメーターが優先され ます。同じパラメーターをオプションHash (`:exclude_begin` と
`:exclude_end`)で指定することもできて、 もし指定されればそれらが最高の優先度を持ちます。 第三の方法の `string_form`
とは、".." や "<..."のことで、ユーザー定義 も可能です(詳しくは {RangeExtd.middle_strings=}()
を参照のこと)。これが、 視覚的には最もわかりやすい方法かも知れません。

`RangeExtd.new()` も上と同意味です。 さらなる解説及び例は、{RangeExtd.initialize}を参照して下さい。

### 少し上級編

```ruby
RangeExtd((0..), true).each do |i|
  print i
  break if i >= 9
end    # => self;  "123456789" => STDOUT
       # *NOT* "012..."
(nil..nil).valid?  # => true
(1...1).valid?     # => false
(1...1).null?      # => true
RangeExtd.valid?(1...1)              # => false
RangeExtd(1, 1, true, true).valid?   # => true
RangeExtd(1, 1, true, true).empty?   # => true
RangeExtd(?a, ?b, true, true).to_a?  # => []
RangeExtd(?a, ?b, true, true).null?  # => true  (empty? is same in this case)
RangeExtd(?a, ?e, true, true).to_a?  # => ["b", "c", "d"]
RangeExtd(?a, ?e, true, true).null?  # => false
RangeExtd::NONE.is_none?             # => true
RangeExtd(1...1, true) == RangeExtd::NONE # => true
RangeExtd::ALL.is_all?               # => true
(nil..nil).is_all?                   # => false
(-Float::INFINITY..Float::INFINITY).is_all?    # => false
(nil..nil).equiv_all?                # => true
(-Float::INFINITY..Float::INFINITY).equiv_all? # => true
(3...7).equiv?(3..6)    # => true
(nil..nil).equiv?(RangeExtd::ALL)    # => true
```

組込Rangeに含まれる全てのメソッドが、(子クラスである){RangeExtd}で使用可能です。

## 詳説

ファイル `range_extd.rb` が読まれた段階で、次の3つのクラスが定義されます。

*   RangeExtd
*   RangeExtd::Infinity
*   RangeExtd::Nowhere


加えて、{Range} クラスと {NilClass}に数個のメソッドが追加また改訂されます。 これらに加えられる改訂は、全て後方互換性を保っています。

この時、{Range} の改訂は、原理的には{RangeExtd}と分離可能だと思います (分離したい人がいるとは思えませんが!)が、{NilClass}
の方は不可避です。 というのも、それなしには{RangeExtd::NONE}が定義不可能だからです。 
具体的には、初期化の時に`ArgumentError` (bad value for range)
の例外が出てしまいます。Rubyの組込みのRangeの仕様のためです。

[Stackoverflow上の議論](https://stackoverflow.com/a/14449380/3577922) を参考にあげておきます。

### RangeExtd::Infinity クラス

{RangeExtd::Infinity} クラスは、基本、定数二つのみを保持するものです。

*   RangeExtd::Infinity::NEGATIVE
*   RangeExtd::Infinity::POSITIVE


これらは、 `Float::INFINITY` を全ての Comparable なオブジェクトに一般化し たものです。メソッド
`<=>`が定義されています。

これらは、他のオブジェクトと同様に普通に使用可能です。たとえば、

```ruby
(RangeExtd::Infinity::NEGATIVE.."k")
```

とはいえ、他には何もメソッドを持っていないため、 Range型のクラスの中以外での使用 はおそらく意味がないでしょう。

なお、Numericのオブジェクトに対しては、原則として `Float::INFINITY` の方 を使って下さい。

ユーザー定義のどの Comparable なクラスに属するどのオブジェクトも、比較 演算子が*標準的な方法で*実装されているという条件付きで、これら二定数と
可換的に比較可能です。「標準的」とは自分の知らないオブジェクトと比較す る際には、上位クラス、究極的には`Object`クラスに判断を委譲する、という
意味です。

さらに詳しくは、マニュアルを参照して下さい(YARD　または RDoc形式で書かれた文書が
コード内部に埋込まれていますし、[RubyGemsのウェブサイト](http://rubygems.org/gems/range_extd)でも閲覧できます
。

### RangeExtd::Nowhere クラス

{RangeExtd::Nowhere} は{NilClass}のように振舞うシングルトンクラスです。 唯一のインスタンスが

*   RangeExtd::Nowhere::NOWHERE


として定義されています。このインスタンスは、たとえば `nil?` に真を返し、 また`nil` と同じ object-ID を `object_id`
で返し、nil と等しい(`==`) です。これは、{RangeExtd::NONE} を構成するために使われます。

なお、Rubyの条件文では、このインスタンスは真(true)であり、偽(false) ではありません。

また、{RangeExtd::NONE} を除き、{RangeExtd::Nowhere::NOWHERE} を含む Range
は、"valid"では*ない*と判断されます(後述)。

### RangeExtd クラス

{RangeExtd} のインスタンスは、 {Range}と同じくイミュータブルです。だから、一度 インスタンスが生成されると、変化しません。

インスタンスの生成方法は上述の通りです(「使用例」の章)。レンジとして"valid"(後述)と 見なされない{RangeExtd}
インスタンスを生成しようとすると、例外(`ArgumentError`)が発生し、 失敗します。

このクラスには、2つの定数が定義されています。

*   RangeExtd::NONE
*   RangeExtd::ALL


前者は、空レンジを表し、後者は全てを含むレンジ、すなわち正負両方向に開いたレンジを表します。

{Range}クラスの通常のメソッド全てに加え、以下が {RangeExtd} と {Range}クラス両方に加え
られています。詳細は、各メソッドのマニュアルを参照下さい(注: 幾つかのメソッドは {Range}クラスのみで定義されていて、 {RangeExtd}
はそれを継承しています)。

*   `exclude_begin?`  ({Range}クラスでは未定義)
*   `valid?` 
*   `empty?` 
*   `null?` 
*   `is_none?`
*   `is_all?` 
*   `equiv?` 


クラスメソッドが三つあります。一番上のものは、 インスタンスメソッドの `valid?` に等価です。

*   `RangeExtd.valid?` 
*   `RangeExtd.middle_strings=(ary)` 
*   `RangeExtd.middle_strings` 


#### 正当性、空かどうか、ヌルかどうかについての詳説

何がレンジとして正当または有効 (`#valid?` => true) かの定義は以下です。

1.  始点と終点とが互いに Comparable であり、かつその比較結果に矛盾がないこと。
    この例外が3つあって、{RangeExtd::NONE}、(Ruby-2.7/2.6で導入された)Beginless/Endless Ranges
    で、 これらはすべて valid です。 たとえば、`(nil..nil)` は{RangeExtd} Ver.2.0+では valid
    です(参考までに、この例は Ruby 1.8 では例外を生じていました)。
2.  {RangeExtd::NONE} と Beginless Rangeを除き `Range#begin` のオブジェクトはメソッド `<=`
    を持たなければなりません。ゆえに、`(true..)`のようなEndless Ranges (Ruby 2.6以上)はvalidでは*ありません*。
    なお、"`true`" もメソッド `<=>` を持っているため、`<=` メソッドによる確認が不可欠です。
3.  同様に、{RangeExtd::NONE} と Endless Rangeを除き `Range#end` のオブジェクトはメソッド `<=`
    を持たなければなりません。ゆえに、`(..true)`のようなBeginless Ranges (Ruby
    2.7以上)はvalidでは*ありません*。
4.  始点は終点と等しい(`==`)か小さくなければなりません。すなわち、 `(begin <=> end)` は、-1 または 0 を返すこと。
5.  もし始点と終点とが等しい時、すなわち `(begin <=> end) == 0`ならば、
    端を除外するかどうかのフラグは両端で一致していなければなりません。 すなわち、もし始点が除外ならば、終点も除外されていなくてはならず、逆も真です。
    その一例として、 `(1...1)` は、"valid" では「ありません」。なぜならば 組込レンジでは、始点を常に含むからです。
    `RangeExtd(1...1, true)` は validで、{RangeExtd::NONE}と等しい(`==`)です。
6.  {RangeExtd::NONE} 以外で{RangeExtd::Nowhere::NOWHERE} を含むRange
    は、validでは*ありません*。


さらなる詳細は {RangeExtd.valid?} と {Range#valid?} のマニュアルを 参照して下さい。

何がレンジとして空({Range#empty?} == `true`)かの定義は以下の通りです。

1.  レンジは、valid であること: `valid?` => true
2.  もしレンジの要素が離散的であれば、すなわち始点の要素がメソッド `succ`
    を持っていれば、レンジ内部に要素が一つも無いことが条件(当然、始点のフラグ は除外になっていなければなりません): `to_a.empty?` =>
    true
3.  もしレンジが連続的であれば、すなわち始点の要素がメソッド `succ` を持っ ていなければ、始点と終点とが等しく (`(begin <=>
    end)` => 0)、かつ両端 のフラグが除外になっていること: `(exclude_begin? && exclude_end?)` =>
    true.


なお、始点と終点とが等しい一方でその除外フラグが一致しない場合は、前節で述べたよ うに
"valid"ではありません。組込レンジは、始点除外フラグが常に偽(`false`)で す。そのため、組込Rangeのオブジェクトで、`empty?`
が真(`true`)にな ることはありません。

さらなる詳細は {Range#empty?} のマニュアルを 参照して下さい。

最後、 {Range#null?} は、「`empty?` または "valid"でない」ことに等 価です。従って、 RangeExtd
オブジェクトにとっては、`null?` は `empty?` に等価です。実用的には、ほとんどのケースにおいて、 {Range#null?}
の方が、{Range#empty?}よりも有用でしょう。

RangeExtd と別の RangeExtd または Rangeの比較 (`<=>`) においては、これら
の定義が考慮されます。そのうちの幾つかは、上の「使用例」の項に示されています。 さらなる詳細は {Range#<=>}、{RangeExtd#<=>}
のマニュアルを参照して下さい。

なお、処理が Rangeオブジェクト内部で閉じている限り、その振舞いは標準 Rubyと同一
で、互換性を保っています。したがって、このライブラリを読込むことで既存のコードに 影響を与えることは原理的にないはずです。

#### 等価性

メソッド `eql?` は、Ruby標準ではハッシュ値を比較して等価性を判断するため、 基本的にオブジェクトのすべてのパラメーターが一致する必要があります。
一方、 `==` はもっと大雑把な比較を行います。以下が一例。

```ruby
RaE(0...0, true) == RaE(?a...?a, true)  # => false
RaE(0...1, true) == RaE(5...6, true)    # => true
```

## 既知のバグ

*   {RangeExtd::Nowhere::NOWHERE} は、{RangeExtd} の文脈では使えません
    (なぜならば{Range#valid?}が偽を返す)が、ユーザーは、Ruby組込み {Range}の枠組み内だけで用いることは以前可能です。
    {RangeExtd::Nowhere::NOWHERE} をnil以外の値として再定義した方が良いかも?
*   このライブラリ Version 2+ は Ruby 2.6 およびそれ以前のバージョンでは動作しません。
*   このライブラリ Version 1は Ruby 1.8 およびそれ以前のバージョンでは動作しません。 Ruby 1.9.3
    ではおそらく大丈夫でしょうが、私は試したことがありません。
*   いくつかの極めて稀な境界条件に於ける挙動は、Rubyのバージョンごとにあ る程度変化しています。例えば、Float::INFINITY
    同士の比較などの挙動が 異なります。同梱のテストスクリプトはかなり網羅的ではあるものの、Ruby
    の多数のバージョンでテストはしておりません。したがって、バージョンに

    よっては、(極めて稀でしょうが)問題が発生する可能性が否定できません。

*   {RangeExtd#hash} メソッドは、ある RangeExtdオブジェに対して常に唯一で排他的な
    数値を返すことが理論保証はされていません。ただし、現実的にそれが破られることは、まず ありません。
*   `RangeExtd::NONE.inspect` と `RangeExtd::NONE.to_s` はいずれも "Null<...Null"
    を返すのだが、Ruby `irb` では "nil...nil" と表示されてしまうために、 とても紛らわしい……。


パッケージに含まれている通り、網羅的なテストが実行されています。

## 開発項目

*   もし {RangeExtd::Infinity::POSITIVE} (と NEGATIVE) が
    ({RangeExtd::Nowhere::NOWHERE}が振舞うように)`nil`のように振る舞えば、
    便利かも知れない。ただし、そのようなオブジェクトを含むRangeは、
    Stringクラスに対してはたとえば`"abcde"[my_nil..]`などで、
    同じようには動かない。Stringクラスは、`nil`について何か厳密なチェックを行っている
    のだろう。だから、仮にそうデザインし直しても、Ruby組込みクラスとの 相性という意味では、使い勝手がずっと向上するということにはなりそうもない。
*   "`similar`" というようなメソッドを定義すれば有用かもしれない。たとえば、
    `(-Float::INFINITY..Float::INFINITY)` と
    `(-Float::INFINITYnil...Float::INFINITY)`
    とは、無限大(無限小)を除外することが無意味であるから、数学的に完全に同一である。
    実際、これらと無限大を含まないRange/Rangearyとの演算の結果には何も影響を 及ぼすことがない。


## 履歴メモ

*   `((?a..?z) === "cc")` は、Ruby 2.6.x 以前は false を返していたが、2.7 以降は true を返す。
*   `(Float::INFINITY..Float::INFINITY).size` は以前は 0を返して
    いた(少なくともRuby-2.1)が、少なくともRuby-2.6以降(Ruby 3含む)では、例外 `FloatDomainError: NaN`
    を発生する。どのバージョンで変化したのかは私は知らない。


### RangeExtd Ver.2

*   {RangeExtd} Ver.2において、Ver.1から、ライブラリのパスがディレクトリ

    の階層一つ上がった。Ruby Gems の慣用にそうため。

*   Ruby-2.7で導入されたBeginless Rangeに対応。
*   `RangeExtd::Infinity#succ` は未定義になった。Floatに合わせた。
*   `Object` と `Numeric` クラスの拡張はデフォルトではなく、オプション化
*   `RangeExtd#eql?`
    [は、Ruby標準(ハッシュ値](#hash)比較)にそうように未定化。{RangeExtd::NONE}を特別扱いすることを廃止。
*   `RangeExtd#min_by` (`max_by` と `minmax_by`)のバグ修正。


### RangeExtd Ver.1.1

{RangeExtd} Ver.1.1 の時点で、the `RangeExtd::Infinity` クラスの インスタンスは
`Float::INFINITY` とは比較できない。

```ruby
RangeExtd::Infinity::POSITIVE != Float::INFINITY  # => true
```

概念として、前者は後者よりもさらに一般化された概念であるから、*等しく* あるべきでない。詳しくは {RangeExtd::Infinity}
マニュアル参照。 Ruby 2.6以上のEndless Range の振舞いは、以下のように一部奇妙に感じるところがある。

```ruby
num1 = (5..Float::INFINITY)
num2 = (5..)
num1.end != num2.end  # => true
num1.size              # => Infinity
num2.size              # => Infinity

str1 = (?a..)
str1.end == num2.end   # => true (because both are nil)
str1.size              # => nil
```

### RangeExtd Ver.1.0

**(注)** `RangeExtd::Infinity::POSITIVE` は、 2018年12月に公式リリースされたRuby 2.6で導入された
[Endless Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
(終端のないRange)で実用上同一です!! 言葉を替えれば、公式Rubyがついに本 ライブラリの一部をサポートしました! ただし、公式Rubyには、
`RangeExtd::Infinity::NEGATIVE` は依然ありません(始端のないRangeがない)。

## 終わりに

RangeExtd内部に閉じた(Rangeでなく)挙動、たとえば RangeExtd同士の比較などは、
全てユーザーにとって自然なもののはずです(と期待します?)。少なくとも、{RangeExtd}に
よってレンジの論理構造が完結した今、これはよく定義されかつ自己矛盾が無いものと言 えましょう。

以前の版のこの章では、以下のように記述していました。

>
ただ、端の無限に開いた、あるいは始点が除外されたレンジの挙動には、一瞬ぎょっとするものが無くはないかも知れないことに注意して下さい。たとえば、片端が小さい方
向に無限に開いて離散的な要素を持つレンジに対してメソッド`member?(obj)` を実行すると、
`nil`が返ります。これは、無限(小)には実質的な意味を持つ `succ()` メソッドが定義されていないためで、したがって与えられた
objがレンジの要素(member)かどうかを調べることが、一般論としては理論的に不可能だからです。これはちょっと不思議に思うかも知れませんが、それはつまり
定命の私たちには無限という概念を計り知るのが容易でない、というだけの話でしょう!

ところが今や、Ruby本家に"beginless Range"組込まれたことで、すべての Rubyプログラマーがこの概念に親しむことになりました。
これは進化と呼びたいです。

とはいえ、RangeExtd と Range との比較は、時には驚きがあるかも知れません。
これは、組込Rangeクラスで許容されているレンジの一部は、始点を除外することを認めた
枠組の中では、前述のように最早有効(valid)と見なされないからです。この枠組に慣れるに
したがって、それらが自然だと思えるようになればいいのですが。保証しますが、一旦こ れに慣れてしまえば、論理的不完全さ極まる混沌とした世界、つまりは
Rangeの現在の挙 動には二度と戻りたくなくなることでしょう!

お楽しみ下さい。

## 著作権他情報

<dl>
<dt>著者</dt>
<dd>   Masa Sakano &lt; info a_t wisebabel dot com &gt;</dd>
<dt>利用許諾条項</dt>
<dd>   MIT.</dd>
<dt>保証</dt>
<dd>   一切無し。</dd>
<dt>バージョン</dt>
<dd>   Semantic Versioning (2.0.0) http://semver.org/</dd>
</dl>



