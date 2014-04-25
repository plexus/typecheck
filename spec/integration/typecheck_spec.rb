require 'spec_helper'

describe Typecheck do
  shared_examples 'valid' do |method, args, result|
    it 'should call the original method' do
      expect(subject.send(method, *args)).to eq result
    end
  end

  shared_examples 'invalid' do |method, args|
    it 'should typecheck' do
      expect{subject.send(method, *args)}.to raise_exception
    end
  end

  let(:checked_class) do
    Class.new do
      extend Typecheck

      def double_me(num)
        num + num
      end
      typecheck 'Numeric -> Numeric', :double_me

      def bad_out(num)
        :sym
      end
      typecheck 'Numeric -> Numeric', :bad_out

      def strsym_num(str, sym)
        str.length
      end
      typecheck 'String, Symbol -> Fixnum', :strsym_num

      def duck(str)
        str.to_str.upcase.intern
      end
      typecheck '#to_str -> Symbol', :duck

      def multi(range)
        ('x' * range.end).chars.drop(range.begin).join.intern
      end
      typecheck '#begin;#end -> Symbol', :multi

      def choice(x)
        :foo
      end
      typecheck '#to_str|Fixnum -> Symbol', :choice

      def arrays(nums, strings)
        (nums + strings.map(&:length)).inject(:+)
      end
      typecheck '[Fixnum],[String] -> Numeric', :arrays

      def optional(num, str = nil, sym = nil)
        num
      end
      typecheck 'Fixnum,String,Symbol -> Numeric', :optional
    end
  end

  subject { checked_class.new }

  include_examples 'valid',   :double_me,  [7], 14
  include_examples 'invalid', :double_me,  ['foo']
  include_examples 'invalid', :double_me,  []

  include_examples 'invalid', :bad_out,    [42]

  include_examples 'valid',   :strsym_num, ['foo', :bar], 3
  include_examples 'invalid', :strsym_num, [:foo, 'bar']

  include_examples 'valid',   :duck,       ['foo'], :FOO
  include_examples 'invalid', :duck,       [7]

  include_examples 'valid',   :multi,      [3..5], :xx
  include_examples 'invalid', :multi,      [Class.new { def begin ; end }.new]
  include_examples 'invalid', :multi,      [7]

  include_examples 'valid',   :choice,     ['foo'], :foo
  include_examples 'valid',   :choice,     [9], :foo
  include_examples 'invalid', :choice,     [5..9]
  include_examples 'invalid', :choice,     [5.9]

  include_examples 'valid',   :arrays,     [[1,2], ['x', 'y']], 5
  include_examples 'invalid', :arrays,     [[:foo], ['x']]

  include_examples 'valid',   :optional,   [1, 'x', :foo], 1
  include_examples 'valid',   :optional,   [1, 'x'], 1
  include_examples 'valid',   :optional,   [1], 1
  include_examples 'invalid', :optional,   [1, 'x', 'y'], 1
  include_examples 'invalid', :optional,   []
end
