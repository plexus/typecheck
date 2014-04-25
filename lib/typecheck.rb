module Typecheck
  VERSION = '0.1.0'

  def typecheck(signature, method)
    alias_method "#{method}_unchecked", method
    define_method method, &SignatureCompiler.new.call(signature, method)
  end

  class SignatureCompiler
    def call(signature, method)
      unchecked_method = "#{method}_unchecked"
      check_args, check_out = parse_sig(signature)
      ->(*args) do
        check_args.(*args)
        send(unchecked_method, *args).tap do |result|
          check_out.(result)
        end
      end
    end

    def parse_sig(sig)
      in_t, out_t = sig.split('->').map(&:strip)
      in_ts = in_t.split(',').map(&:strip)

      in_checks = in_ts.map(&method(:parse_type_list))
      out_check = parse_type_list(out_t)

      args_checker = ->(*args) {
        args.each.with_index do |arg, idx|
          in_checks[idx].(arg)
        end
      }
      [args_checker, out_check]
    end

    def pred_or(preds)
      ->(value) { preds.any?{|pred| pred.(value) } }
    end

    def pred_and(preds)
      ->(value) { preds.all?{|pred| pred.(value) } }
    end

    def parse_type_list(choices)
      types = choices.split('|').map(&:strip)
      pred_or [
        pred_or(types.map {|choice|
            parse_type(choice, :check)
          }),
        pred_or(types.map {|choice|
            parse_type(choice, :raise)
          })
      ]
    end

    def parse_type(subtype, check_or_raise)
      pred_and subtype.split(';').map(&:strip).map { |type|
        case type
        when /#(.*)/
          method("#{check_or_raise}_respond_to").to_proc.curry.($1)
        when /\[(.*)\]/
          method("#{check_or_raise}_array").to_proc.curry.(eval($1))
        else
          method("#{check_or_raise}_class").to_proc.curry.(eval(type))
        end
      }
    end

    def check_respond_to(method, value)
      value.respond_to? method
    end

    def raise_respond_to(method, value)
      raise "Expected #{value.inspect}, to respond_to #{method}" unless check_respond_to(method, value)
    end

    def check_array(type, array)
      array.all? {|element| check_class(type, element) }
    end

    def raise_array(type, array)
      raise "Bad type: #{array.inspect} to only contain #{klz}" unless check_array(type, array)
    end

    def check_class(klz, value)
      value.is_a? klz
    end

    def raise_class(klz, value)
      raise "Bad type: #{value.inspect}, expected #{klz}" unless check_class(klz, value)
    end
  end
end
