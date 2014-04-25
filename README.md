[![Gem Version](https://badge.fury.io/rb/typecheck.png)][gem]
[![Build Status](https://secure.travis-ci.org/plexus/typecheck.png?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/plexus/typecheck.png)][codeclimate]

[gem]: https://rubygems.org/gems/typecheck
[travis]: https://travis-ci.org/plexus/typecheck
[codeclimate]: https://codeclimate.com/github/plexus/typecheck

# Typecheck

Type checking for Ruby methods.

Validate the arguments and return value of a function, based on a type signature. Supports duck-type checking.

```ruby
require 'timecheck'

class Checked
  extend Typecheck

  typecheck 'Numeric -> Numeric',
  def double_me(num)
    num + num
  end

  typecheck 'String, Symbol -> Fixnum',
  def strsym_num(str, sym)
    str.length
  end

  typecheck '#to_str -> Symbol',
  def duck(str)
    str.to_str.upcase.intern
  end

  typecheck '#begin;#end -> Symbol',
  def multi(range)
    ('x' * range.end).chars.drop(range.begin).join.intern
  end

  typecheck '#to_str|Fixnum -> Symbol',
  def choice(x)
    :foo
  end

  typecheck '[Fixnum],[String] -> Numeric',
  def arrays(nums, strings)
    (nums + strings.map(&:length)).inject(:+)
  end

  typecheck 'Fixnum,String,Symbol -> Numeric',
  def optional(num, str = nil, sym = nil)
    num
  end
end
```