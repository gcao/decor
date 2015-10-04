require "decor/version"

module Decor
  def decor &block
    puts "decor"

    eigen_class = class << self; self; end
    eigen_class.instance_eval do
      # TODO check if method_added is inherited or part of this class/module
      # Re-add method_added hook only if it's not inherited
      # TODO singleton_method_added
      orig_method_added = method(:method_added)

      define_method :method_added do |name|
        return if name == :method_added

        begin
          # Disable method_added
          eigen_class.send :define_method, :method_added do |method| end

          puts "method_added(#{name})"
          m = instance_method(name)
          define_method name do |*args|
            puts "generated #{name}"
            instance_exec m.name, *args, &block
            m.bind(self).call *args
          end
        ensure
          orig_method_added.call(name)
          eigen_class.send :define_method, :method_added, orig_method_added
        end
      end
    end
  end
end

class A
  extend Decor

  decor {|method| puts "decor #{method}"}
  def test
    puts 'test'
  end
end

A.new.test

# Here is how I ran this script directly from vim =>   :!ruby -Ilib %
# Expected output
#decor
#method_added(test)
#generated test
#decor test
#test
#

puts "----------------------"

module Strict
  def self.included target
    target.extend Decor
    target.extend ClassMethods
  end

  module ClassMethods
    def match *types
      puts "match #{types.inspect[1..-2]}"
      decor do |method, *args|

      end
    end
  end
end

class B
  include Strict

  match Integer
  match Integer => Integer
  match Integer, Integer => Integer
  def test *arg
  end
end

B.new.test 'test'

