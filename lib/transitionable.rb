require 'transitionable/version'
require 'active_support/concern'
require 'active_support/core_ext/object'

module Transitionable

  extend ActiveSupport::Concern

  class InvalidStateTransition < StandardError
    def initialize(from_state, to_state)
      msg = "Can't transition from #{from_state} to #{to_state}."
      super(msg)
    end
  end

  module ClassMethods
    attr_accessor :trans_column

    def transition(column)
      self.trans_column = column
      self::STATES.values.each do |this_state|
        define_method "#{this_state}?" do
          transitionable_state == this_state
        end
      end
    end
  end

  def transitionable_state
    self.send(self.class.trans_column)
  end

  def validate_transition!(target_state:)
    unless validate_transition(target_state: target_state)
      raise InvalidStateTransition.new(transitionable_state, target_state)
    end
    true
  end

  def validate_transition(target_state:)
    self.class::TRANSITIONS.detect do |transition|
      transition[:from] == transitionable_state && transition[:to] == target_state
    end.present? ? true : false
  end

end
