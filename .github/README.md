
# RangeExtd - Extended Range class with exclude_begin and open-ends

This package contains RangeExtd class, the Extended Range class that features:

    1. includes exclude_begin? (to exclude the "begin" boundary),
    2. allows open-ended range (to the infinity),
    3. defines NONE and ALL constants,
    4. the first self-consistent logical structure,
    5. complete backward-compatibility within the built-in Range.

With the introduction of the excluded status of begin, in addition to the end
as in built-in Range, and open-ended feature, the logical completeness of the
1-dimensional range is realised.

Then the validity of range is strictly defined now. Following that, this
package adds a few methods, most notably {Range#valid?} and {Range#empty?} to
Range, and accordingly its any sub-classes,

For example, `(3...3).valid?`  returns false, because the element 3 is
inclusive for the begin boundary, yet exclusive for the end boundary, which
are contradictory to each other.  With this RangeExtd class, it is expressed
as a valid range,

*   RangeExtd.new(3, 3, true,  true)   # => an empty range
*   RangeExtd.new(3, 3, false, false)  # => a single-point range (3..3)


However, as long as it is within built-in Range, nothing has changed, so it is
completely compatible with the standard Ruby.

To express open-ended ranges is simple; you just use either of the two
(negative and positive, or former and later) constants defined in the class
{RangeExtd::Infinity}

*   RangeExtd::Infinity::NEGATIVE
*   RangeExtd::Infinity::POSITIVE


They are basically the object that generalised `Float::INFINITY` to any
Comparable object.  For example,

    ("a"..RangeExtd::Infinity::POSITIVE).each

gives an infinite iterator with `String#succ`, starting from "a" (therefore,
make sure to code so it breaks the iterator at one stage!).

The built-in Range class is very useful, and has given Ruby users a power to
make easy coding.  Yet, the lack of definition of exclusive begin boundary is
a nuisance in some cases.

Having said that, there is a definite and understandable reason; Range in Ruby
is not limited at all to Numeric (or strictly speaking, Real number or its
representative).  Range with any object that has a method of `succ()` is found
to be useful, whereas there is no reverse method for `succ()` in general. In
that sense Range is inherently not symmetric.  In addition some regular Range
objects are continuous (like Float), while others are discrete (like Integer
or String).  That may add some confusion to the strict definition.

To add the feature of the exclusive begin boundary is in that sense not 100
per cent trivial.  The definition I adopt for the behaviour of RangeExtd is
probably not the only solution.  Personally, I am content with it, and I think
it achieves the good logical completeness within the frame.

I hope you find this package to be useful.

### News: Endless Range supported

Now, as of 2019 October, this fully supports [Endless
Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
introduced in Ruby 2.6.  It is released as Version 1.* finally!

#### NOTE: Relationship with Rangeary

The class to handle multiple Ranges with objects of the same class (most
typically Float), [Rangeary](https://rubygems.org/gems/rangeary) uses this
library to fullest, because the concept of potentially open-ended Range on
both begin and end is essential to realise it.  For example, the negation of
Range +(?a..?d)+ is Ranges +(-"Infinity-Character"...3)+ and
+(?d(exclusive).."Infinity-Character")+ and its negation is back to the
original +(?a..?d)+.  Such operations are possible only with this class
`RangeExtd` 

Rangeary: https://rubygems.org/gems/rangeary

#### NOTE: Relationship with Rangesmaller

This package RangeExtd supersedes the obsolete
[Rangesmaller](https://rubygems.org/gems/rangesmaller) package and class, with
the added open-ended feature, and a different interface in creating a new
instance. https://rubygems.org/gems/rangesmaller

## Install

    gem install range_extd

Two files

    range_extd/range_extd.rb
    range_extd/infinity/infinity.rb

should be installed in one of your `$LOAD_PATH` 

Alternatively get it from

    http://rubygems.org/gems/range_extd

Then all you need to do is

    require 'range_extd/range_extd'

or, possibly as follows, if you manually install it

    require 'range_extd'

in your Ruby script (or irb).  The other file

    range_extd/infinity/infinity.rb

is called (required) from it automatically.

Have fun!

## Simple Examples

### How to create a RangeExtd instance

Here are some simple examples.

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

Basically, there are three forms:

    RangeExtd(range, [exclude_begin=false, [exclude_end=false]], opts)
    RangeExtd(obj_begin, obj_end, [exclude_begin=false, [exclude_end=false]], opts)
    RangeExtd(obj_begin, string_form, obj_end, [exclude_begin=false, [exclude_end=false]], opts)

The two parameters in the brackets specify the respective boundary to be
excluded if true, or included if false (Default).  If they contradict to the
first parameter of the range (Range or RangeExtd), those latter two parameters
are used. Also, you can specify the same parameters as the options
`:exclude_begin` and `:exclude_end`, which have the highest priority, if
specified. The `string_form` in the third form is like ".." and "<...", which
can be defined by a user (see {RangeExtd.middle_strings=}() for detail), and
is arguably the most visibly recognisable way for any range with
`exclude_begin=true`.

`RangeExtd.new()` is the same thing. For more detail and examples, see
{RangeExtd.initialize}.

### Slightly more advanced uses

    (1..RangeExtd::Infinity::POSITIVE).each do |i|
      print i
      break if i >= 9
    end    # => self ( "123456789" => STDOUT )
    (nil..nil).valid?  # => false
    (1...1).valid?     # => false
    (1...1).null?      # => true
    RangeExtd.valid?(1...1)              # => false
    RangeExtd(1, 1, true, true).valid?   # => true
    RangeExtd(1, 1, true, true).empty?   # => true
    RangeExtd(?a, ?b, true, true).to_a?  # => []
    RangeExtd(?a, ?b, true, true).empty? # => true
    RangeExtd(?a, ?e, true, true).to_a?  # => ["b", "c", "d"]
    RangeExtd(?a, ?e, true, true).empty? # => false
    RangeExtd::NONE.is_none?             # => true
    RangeExtd::ALL.is_all?               # => true
    (3...7).equiv?(3..6)    # => true

All the methods that are in the built-in Range can be used.

## Description

Once the file `range_extd/range_extd.rb` is required, the two classes are
defined:

*   RangeExtd
*   RangeExtd::Infinity


Also, several methods are added or altered in Range class. All the changes
made in Range are backward-compatible with the original.

### RangeExtd::Infinity Class

Class {RangeExtd::Infinity} has basically only two constant instances.

*   RangeExtd::Infinity::NEGATIVE
*   RangeExtd::Infinity::POSITIVE


They are the objects that generalise the concept of `Float::INFINITY`  to any
Comparable objects.  The methods `<=>` and `succ`  are defined.

You can use them the same as other objects, such as,

    ("k"..RangeExtd::Infinity::POSITIVE)

However as they do not have any other methods, the use out of Range-type class
is probably meaningless.

Note for any Numeric object, please use `Float::INFINITY` instead in
principle.

Any objects in any user-defined Comparable class are commutatively comparable
with those two constants, as long as the cmp method of the class is written
politely.

For more detail, see its documents (YARD or RDoc-style documents embedded in
the code, or see [RubyGems webpage](http://rubygems.org/gems/range_extd)).

***Note*** `RangeExtd::Infinity::POSITIVE` is practically the same as [Endless
Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
introduced in Ruby 2.6 released in 2018 December!!  In other words, the
official Ruby has finally implement a part of this library! However,
`RangeExtd::Infinity::NEGATIVE` is not yet implemented in the official Ruby
Range (it has no "boundless begin"), and hence this library still has some
use, which supplements the mathematical incompleteness of the standard Range
in the official Ruby.

### RangeExtd Class

RangeExtd objects are immutable, the same as Range. Hence once an instance is
created, it would not change.

How to create an instance is explained above (in the Examples sections).  Any
attempt to try to create an instance that is not "valid" as a range (see
below) raises an exception (`ArgumentError`), and fails.

There are two constants defined in this class:

*   RangeExtd::NONE
*   RangeExtd::ALL


The former represents the empty range and the latter does the range covers
everything, namely open-ended for the both negative and positive directions.

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


What is valid (`#valid?` => true) as a range is defined as follows.

1.  Both `begin` and `end` elements must be Comparable to each other, and the
    comparison results must be consistent between the two. The sole exception
    is {RangeExtd::NONE}, which is valid. For example, `(nil..nil)` is NOT
    valid (nb., it raised Exception in Ruby 1.8).
2.  begin must be smaller than or equal (`==`) to end, that is, `(begin <=>
    end)` must be either -1 or 0.
3.  If begin is equal to end, namely, `(begin <=> end) == 0`, the exclude
    status of the both ends must agree. That is, if the `begin` is excluded,
    `end` must be also excluded, and vice versa. For example, `(1...1)` is NOT
    valid for that reason, because any built-in Range object has the exclude
    status of false (namely, inclusive) for `begin`.


For more detail and examples see the documents of {RangeExtd.valid?} and
{Range#valid?} 

The definition of what is empty (`#empty?` => true) as a range is as follows;

1.  the range must be valid: `valid?` => true
2.  if the range id discrete, that is, begin has `succ` method, there must be
    no member within the range (which means the begin must be excluded, too): 
    `to_a.empty?` => true
3.  if the range is continuous, that is, begin does not have `succ` method,
    begin and end must be equal (`(begin <=> end)` => 0) and both the
    boundaries must be excluded: `(exclude_begin? && exclude_end?)` => true.


Note that ranges with equal `begin` and `end` with inconsistent two exclude
status are not valid, as mentioned in the previous paragraph. The built-in
Range always has the begin-exclude status of `false`.  For that reason, no
instance of built-in Range  has the status of `empty?` of `true`.

For more detail and examples see the documents of {Range#empty?} 

Finally, {Range#null?} is equivalent to "either empty or not valid".
Therefore, for RangeExtd objects `null?` is equivalent to `empty?`.

In comparison (`<=>`) between a RangeExtd and another RangeExtd or Range
object, those definitions are taken into account. Some of them are shown in
the above Examples section. For more detail, see {Range#==}> and
{RangeExtd#==}>, as well as `#eql?`.

Note that as long as the operation is within Range objects, the behaviour is
identical to the standard Ruby -- it is completely compatible.  Therefore,
requiring this library would not affect any existing code in principle.

## Known bugs

*   Note this library does not work in Ruby 1.8 or earlier. For Ruby 1.9.3 it
    is probably all right, though I have never tested it.
*   Some unusual (rare) boundary conditions are found to vary from version to
    version in Ruby, such as an implementation of +Hash#=>+. Though the test
    scripts are pretty extensive, they have not been performed over many
    different versions of Ruby. Hence, some features may not work well in some
    particular versions, although such cases should be very rare.
*   {RangeExtd#hash} method does not theoretically guarantee to return a
    unique number for a {RangeExtd} object, though to encounter a hash number
    that is used elsewhere is extremely unlikely to happen in reality.


Extensive tests have been performed, as included in the package.

## ToDo

Nothing on the horizon.

## Final notes

All the behaviours within RangeExtd (not Range), such as any comparison
between two RangeExtd, should be (or hopefully?) natural for you.  At least it
is well-defined and self-consistent, as the logical structure of the ranges is
now complete with RangeExtd. Note some behaviours for open-ended or
begin-excluded ranges may give you a little shock at first.  For example, the
method `member?(obj)` for an open-ended range for the negative direction with
discrete elements returns `nil`.  That is because no meaningful method of
`succ()` is defined for the (negative) infinity, hence it is theoretically
impossible in general to check whether the given obj is a member of the range
or not.  You may find it to be weird, but that just means the concept of the
infinity is unfamiliar to us mortals!

On the other hand, the comparison between RangeExtd and Range may have more
occasional surprises.  That is because some of the accepted ranges by built-in
Range class are no longer valid in this framework with the inclusion of
exclude-status of the begin boundary, as explained. Hopefully you will feel it
to be natural as you get accustomed to it. And I bet once you have got
accustomed to it, you will never want to go back to the messy world of logical
incompleteness, that is, the current behaviour of Range!

Enjoy.


## Miscellaneous

## Copyright etc

Author
:   Masa Sakano < imagine a_t sakano dot co dot uk >
License
:   MIT.
Warranty
:   No warranty whatsoever.
Versions
:   The versions of this package follow Semantic Versioning (2.0.0)
    http://semver.org/


---

# RangeExtd - 拡張Rangeクラス - exclude_begin と無限大に開いた範囲と

このパッケージは、Range を拡張した RangeExtd クラスを定義しています。 以下の特徴を持ちます。

    1. メソッド exclude_begin? の導入 (レンジの始点を除外できる),
    2. (無限大に)開いたレンジ
    3. NONE (空レンジ) と ALL (全範囲レンジ)定数の導入
    4. 初めて自己論理的に完結したレンジ構造の達成
    5. 組込Rangeとの完全後方互換性

組込Rangeにある exclude_end に加えて、exclude_beginを導入したこと、及
び無限大へ開いた範囲を許可したことで、一次元上の範囲の論理的完全性を実 現しました。

これにより、レンジの有効性を厳密に定義しています。それに従って、数個の メソッドを
Range及び(自然に)そのサブクラスに追加しました。なかでも特徴的なのが、 {Range#valid?} と {Range#empty?} です。

たとえば、`(3...3).valid?` は偽を返します。要素の 3 が、始点と しては含まれているのに対し、終点としては除外されていて、これは相互に矛
盾しているためです。ここで導入する RangeExtdクラスにおいては、以下のよ うにこれが有効なレンジとして定義できます。

*   RangeExtd.new(3, 3, true,  true)   # => 空レンジ
*   RangeExtd.new(3, 3, false, false)  # => 一点レンジ (3..3)


しかしながら、組込Rangeの範囲内に収まっている限り、何も変わっていませ ん。つまり、標準の Rubyとの完全な後方互換性を実現しています。

無限に開いたレンジを表すのは簡単です。単に {RangeExtd::Infinity}クラスで
定義されている二つの定数(無限大または無現小、あるいは無限前と無限後)の いずれかを用います。

*   RangeExtd::Infinity::NEGATIVE
*   RangeExtd::Infinity::POSITIVE


これらは基本的に `Float::INFINITY` を全ての Comparableであるオ ブジェクトに一般化したものです。たとえば、

    ("a"..RangeExtd::Infinity::POSITIVE).each

は、"a"から始まる `String#succ` を使った無限のイテレーターを与えます (だから、どこかで必ず
breakするようにコードを書きましょう!)。

組込 Rangeは大変有用なクラスであり、Rubyユーザーに容易なプログラミングを可能にす
るツールでした。しかし、始点を除外することができないのが玉に瑕でありました。

ただし、それにはれっきとした理由があることは分かります。Rubyの Rangeは、Numeric
(厳密にはその実数を表現したもの)だけに限ったものではありません。 `succ()` メソッ ドを持つオブジェクトによる
Rangeは極めて有用です。一方、`succ()` の逆に相 当するメソッドは一般的には定義されていません。そういう意味で、Rangeは本質的に非
対称です。加えて、よく使われる Rangeオブジェクトのうちあるもの(たとえば Float)は 連続的なのに対し、そうでないものも普通です(たとえば
Integer や String)。この状況 が厳密な定義をする時の混乱に拍車をかけています。

ここで始点を除外可能としたことは、そういう意味で、道筋が100パーセント明らかなも のではありませんでした。ここで私が採用した
RangeExtdクラスの定義は、おそらく、考え られる唯一のものではないでしょう。とはいえ、個人的には満足のいくものに仕上がりま
したし、このレンジという枠内での論理的完全性をうまく達成できたと思います。

このクラスが少なからぬ人に有用なものであることを願ってここにリリースします。

### News: Endless Range サポートしました

2019年10月より、本パッケージは、Ruby 2.6 で導入された [Endless
Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
(終端のない Range)を正式サポートしました。よって、Version 1.0 をリリースしました!

#### 注: Rangearyとの関係

同クラス(典型的にはFloat)のオブジェクトからなる複数のRangeを扱うクラス
[Rangeary](https://rubygems.org/gems/rangeary) は、本ライブラリを使い
切っています。Rangeを実現するためには、始端と終端との両方で開いた可能 性があるRangeを扱うことが必須だからです。例えば、 Range
+(?a..?d)+ の否定は、複数Range +(-"Infinity(文字)"...3)+ と +(?d(始端除外).."Infinity(文字)")+
であり、その否定は、元の +(?a..?d)+ です。このような演算は、`RangeExtd` があって初めて可能になります。

Rangeary: https://rubygems.org/gems/rangeary

#### 注: Rangesmallerとの関係

このパッケージは、(今やサポートされていない) [Rangesmaller](https://rubygems.org/gems/rangesmaller)
パッケージ及びクラスを 後継するものです。同クラスの機能に、無限に開いた範囲を許す機能が加わり、また、オ
ブジェクト生成時のインターフェースが変更されています。 https://rubygems.org/gems/rangesmaller

## インストール

    gem install range_extd

により、ファイルが 2個、

    range_extd/range_extd.rb
    range_extd/infinity/infinity.rb

`$LOAD_PATH` の一カ所にインストールされるはずです。

あるいは、パッケージを以下から入手できます。

    http://rubygems.org/gems/range_extd

後は、Ruby のコード(又は irb)から

    require 'range_extd/range_extd'

とするだけです。もしくは、特に手でインストールした場合は、

    require 'range_extd'

とする必要があるかも知れません。もう一方のファイル

    range_extd/infinity/infinity.rb

は、自動的に読み込まれます。

お楽しみあれ!

## 単純な使用例

### RangeExtd インスタンスを作成する方法

以下に幾つかの基本的な使用例を列挙します。

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

インスタンスを作成するのには、三通りあります。

    RangeExtd(range, [exclude_begin=false, [exclude_end=false]], opts)
    RangeExtd(obj_begin, obj_end, [exclude_begin=false, [exclude_end=false]], opts)
    RangeExtd(obj_begin, string_form, obj_end, [exclude_begin=false, [exclude_end=false]], opts)

大括弧の中の二つのパラメーターが、それぞれ始点と終点とを除外する(true)、または含む
(false)を指示します。もし、その二つのパラメーターが最初のパラメーターのレンジ (Range or RangeExtd)
と矛盾する場合は、ここで与えた二つのパラメーターが優先され ます。同じパラメーターをオプションHash (`:exclude_begin` と
`:exclude_end`)で指定することもできて、 もし指定されればそれらが最高の優先度を持ちます。 第三の方法の `string_form`
とは、".." や "<..."のことで、ユーザー定義 も可能です(詳しくは {RangeExtd.middle_strings=}()
を参照のこと)。これが、 視覚的には最もわかりやすい方法かも知れません。

`RangeExtd.new()` も上と同意味です。 さらなる解説及び例は、{RangeExtd.initialize}を参照して下さい。

### 少し上級編

    (1..RangeExtd::Infinity::POSITIVE).each do |i|
      print i
      break if i >= 9
    end    # => self ( "123456789" => STDOUT )
    (nil..nil).valid?  # => false
    (1...1).valid?     # => false
    (1...1).null?      # => true
    RangeExtd.valid?(1...1)              # => false
    RangeExtd(1, 1, true, true).valid?   # => true
    RangeExtd(1, 1, true, true).empty?   # => true
    RangeExtd(?a, ?b, true, true).to_a?  # => []
    RangeExtd(?a, ?b, true, true).empty? # => true
    RangeExtd(?a, ?e, true, true).to_a?  # => ["b", "c", "d"]
    RangeExtd(?a, ?e, true, true).empty? # => false
    RangeExtd::NONE.is_none?             # => true
    RangeExtd::ALL.is_all?               # => true
    (3...7).equiv?(3..6)    # => true

組込Rangeに含まれる全てのメソッドが使用可能です。

## 詳説

ファイル `range_extd/range_extd.rb` が読まれた段階で、次の二つのクラスが定義されます。

*   RangeExtd
*   RangeExtd::Infinity


加えて、Range クラスに数個のメソッドが追加また改訂されます。Rangeクラスに加えら れる改変は、全て後方互換性を保っています。

### RangeExtd::Infinity クラス

{RangeExtd::Infinity} クラスは、基本、定数二つのみを保持するものです。

*   RangeExtd::Infinity::NEGATIVE
*   RangeExtd::Infinity::POSITIVE


これらは、 `Float::INFINITY` を全ての Comparable なオブジェクトに一般化し たものです。メソッド `<=>` と `succ`
が定義されています。

これらは、他のオブジェクトと同様に普通に使用可能です。たとえば、
    ("k"..RangeExtd::Infinity::POSITIVE)

とはいえ、他には何もメソッドを持っていないため、 Range型のクラスの中以外での使用 はおそらく意味がないでしょう。

なお、Numericのオブジェクトに対しては、原則として `Float::INFINITY` の方 を使って下さい。

ユーザー定義のどの Comparable なクラスに属するどのオブジェクトも、これら二定数と
可換的に比較可能です。その際、同クラスに置ける比較メソッドがマナー良く書かれてあ る、という前提で。

さらに詳しくは、マニュアルを参照して下さい(YARD　または RDoc形式で書かれた文書が
コード内部に埋込まれていますし、[RubyGemsのウェブサイト](http://rubygems.org/gems/range_extd)でも閲覧できます
。

**(注)** `RangeExtd::Infinity::POSITIVE` は、 2018年12月に公式リリースされたRuby 2.6で導入された
[Endless
Range](https://rubyreferences.github.io/rubychanges/2.6.html#endless-range-1)
(終端のないRange)で実用上同一です!! 言葉を替えれば、公式Rubyがついに本 ライブラリの一部をサポートしました! ただし、公式Rubyには、
`RangeExtd::Infinity::NEGATIVE` は依然ありません(始端のないRangeがない)。
本ライブラリにより、組込Rangeに欠けている数学的不完全性を補うことができます。

### RangeExtd クラス

RangeExtd のインスタンスは、 Rangeと同じくイミュータブルです。だから、一度インス タンスが生成されると、変化しません。

インスタンスの生成方法は上述の通りです(「使用例」の章)。レンジとして"valid"(後述)と見
なされないインスタンスを生成しようとすると、例外(`ArgumentError`)が発生し、 失敗します。

このクラスには、二つの定数が定義されています。

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


何がレンジとして有効 (`#valid?` => true) かの定義は以下です。

1.  始点と終点とが互いに Comparable であり、かつその比較結果に矛盾がないこと。 この唯一の例外は {RangeExtd::NONE}
    で、これは valid です。 たとえば、`(nil..nil)` は valid では「ありません」(参考までに、この例は Ruby 1.8
    では例外を生じていました)。
2.  始点は終点と等しい(`==`)か小さくなければなりません。すなわし、 `(begin <=> end)` は、-1 または 0 を返すこと。
3.  もし始点と終点とが等しい時、すなわち `(begin <=> end) == 0`ならば、
    端を除外するかどうかのフラグは両端で一致していなければなりません。 すなわち、もし始点が除外ならば、終点も除外されていなくてはならず、逆も真です。
    その一例として、 `(1...1)` は、"valid" では「ありません」。なぜならば 組込レンジでは、始点を常に含むからです。


さらなる詳細は {RangeExtd.valid?} と {Range#valid?} のマニュアルを 参照して下さい。

何がレンジとして空(`#empty?` => true)かの定義は以下の通りです。

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
オブジェクトにとっては、`null?` は `empty?` に等価です。

RangeExtd と別の RangeExtd または Rangeの比較 (`<=>`) においては、これら
の定義が考慮されます。そのうちの幾つかは、上の「使用例」の項に示されています。 さらなる詳細は {Range#==}、{RangeExtd#==} および
`#eql?` のマニュアルを参照して下さい。

なお、処理が Rangeオブジェクト内部で閉じている限り、その振舞いは標準 Rubyと同一
で、互換性を保っています。したがって、このライブラリを読込むことで既存のコードに 影響を与えることは原理的にないはずです。

## 既知のバグ

*   このライブラリは Ruby 1.8 およびそれ以前のバージョンでは動作しません。 Ruby 1.9.3
    ではおそらく大丈夫でしょうが、私は試したことがありません。
*   いくつかの極めて稀な境界条件に於ける挙動は、Rubyのバージョンごとにあ る程度変化しています。例えば、Float::INFINITY
    同士の比較などの挙動が 異なります。同梱のテストスクリプトはかなり網羅的ではあるものの、Ruby
    の多数のバージョンでテストはしておりません。したがって、バージョンに

    よっては、(極めて稀でしょうが)問題が発生する可能性が否定できません。

*   {RangeExtd#hash} メソッドは、ある RangeExtdオブジェに対して常に唯一で排他的な
    数値を返すことが理論保証はされていません。ただし、現実的にそれが破られることは、まず ありません。


パッケージに含まれている通り、網羅的なテストが実行されています。

## 開発項目

特になし。

## 終わりに

RangeExtd内部に閉じた(Rangeでなく)挙動、たとえば RangeExtd同士の比較などは、
全てユーザーにとって自然なもののはずです(と期待します?)。少なくとも、RangeExtdに
よってレンジの論理構造が完結した今、これはよく定義されかつ自己矛盾が無いものと言
えましょう。ただ、端の無限に開いた、あるいは始点が除外されたレンジの挙動には、 一瞬ぎょっとするものが無くはないかも知れないことに注意して下さい。たとえば、
片端が小さい方向に無限に開いて離散的な要素を持つレンジに対してメソッド `member?(obj)` を実行すると、
`nil`が返ります。これは、無限(小)に は実質的な意味を持つ `succ()` メソッドが定義されていないためで、したがっ て与えられた
objがレンジの要素(member)かどうかを調べることが、一般論としては理論
的に不可能だからです。これはちょっと不思議に思うかも知れませんが、それはつまり定
命の私たちには無限という概念を計り知るのが容易でない、というだけの話でしょう!

一方、RangeExtd と Range との比較は、それ以上に驚くことがあるかも知れません。こ
れは、組込Rangeクラスで許容されているレンジの一部は、始点を除外することを認めた
枠組の中では、前述のように最早有効(valid)と見なされないからです。この枠組に慣れるに
したがって、それらが自然だと思えるようになればいいのですが。保証しますが、一旦こ れに慣れてしまえば、論理的不完全さ極まる混沌とした世界、つまりは
Rangeの現在の挙 動には二度と戻りたくなくなることでしょう!

お楽しみ下さい。

## その他

## 著作権他情報

著者
:   Masa Sakano < imagine a_t sakano dot co dot uk >
利用許諾条項
:   MIT.
保証
:   一切無し。
バージョン
:   Semantic Versioning (2.0.0) http://semver.org/


