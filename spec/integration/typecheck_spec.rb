require 'spec_helper'

describe Typecheck do
  shared_examples 'valid' do |method, args, result|
    it 'should call the original method' do
      expect(subject.send(method, *args)).to eq result
    end
  end

  shared_examples 'invalid' do |method, args, message = '', error = Typecheck::TypeError|
    it 'should typecheck' do
      expect{subject.send(method, *args)}.to raise_error(error, message)
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
      typecheck '#begin; #end -> Symbol', :multi

      def multi2(comp_enum)
        :foo
      end
      typecheck 'Comparable;Enumerable -> Symbol', :multi2

      def multi3(comp_enum)
        :foo
      end
      typecheck '[Fixnum];[String] -> Symbol', :multi3

      def choice(x)
        :foo
      end
      typecheck '#to_str | Fixnum ->   Symbol', :choice

      def arrays(nums, strings)
        (nums + strings.map(&:length)).inject(:+)
      end
      typecheck '[Fixnum],[String] -> Numeric', :arrays

      def optional(num, str = nil, sym = nil)
        num
      end
      typecheck 'Fixnum,  String, Symbol -> Numeric', :optional
    end
  end

  subject { checked_class.new }
  comparable = Class.new { include Comparable }.new

  include_examples 'valid',   :double_me,  [7], 14
  include_examples 'invalid', :double_me,  ['foo'], 'Bad type: "foo", expected Numeric'
  include_examples 'invalid', :double_me,  [], 'wrong number of arguments (0 for 1)', ArgumentError

  include_examples 'invalid', :bad_out,    [42], 'Bad type: :sym, expected Numeric'

  include_examples 'valid',   :strsym_num, ['foo', :bar], 3
  include_examples 'invalid', :strsym_num, [:foo, 'bar'], 'Bad type: :foo, expected String'

  include_examples 'valid',   :duck,       ['foo'], :FOO
  include_examples 'invalid', :duck,       [7], /to respond_to to_str/

  include_examples 'valid',   :multi,      [3..5], :xx
  include_examples 'invalid', :multi,      [Class.new { def begin ; end }.new], /to respond_to end/
  include_examples 'invalid', :multi,      [7], /to respond_to begin/
  include_examples 'invalid', :multi,      ["foo"], /Expected "foo", to respond_to begin/

  include_examples 'invalid', :multi2,     [3..6], /Bad type.* expected Comparable/
  include_examples 'invalid', :multi2,     [comparable], /Bad type.* expected Enumerable/

  include_examples 'invalid', :multi3,     [[3.5]], 'Bad type: expected [3.5] to only contain Fixnum'
  include_examples 'invalid', :multi3,     [[3]], /to only contain String/

  include_examples 'valid',   :choice,     ['foo'], :foo
  include_examples 'valid',   :choice,     [9], :foo
  include_examples 'invalid', :choice,     [5..9], /Expected 5..9, to respond_to to_str/
  include_examples 'invalid', :choice,     [5.9], /Expected 5.9, to respond_to to_str/

  include_examples 'valid',   :arrays,     [[1,2], ['x', 'y']], 5
  include_examples 'invalid', :arrays,     [[:foo], ['x']], /\[:foo\] to only contain Fixnum/

  include_examples 'valid',   :optional,   [1, 'x', :foo], 1
  include_examples 'valid',   :optional,   [1, 'x'], 1
  include_examples 'valid',   :optional,   [1], 1
  include_examples 'invalid', :optional,   [1, 'x', 'y'], 1, 'Bad type: "y", expected Symbol'
  include_examples 'invalid', :optional,   [],  /wrong number of arguments/, ArgumentError

  it 'should make the original method available' do
    expect(subject.double_me_unchecked('foo')).to eq 'foofoo'
  end

  describe Typecheck::SignatureCompiler do
    describe '#parse_type' do
      let(:compiler) { Typecheck::SignatureCompiler.new }

      it 'should work with ; for "or"' do
        x = Class.new { def begin ; end }.new

        expect( compiler.parse_type('#begin;#end', :check).(x) ).to be false
        expect{ compiler.raise_respond_to('end', x) }.to raise_error
        expect{ compiler.parse_type('#begin;#end', :raise).(x) }.to raise_error
      end
    end
  end

end
