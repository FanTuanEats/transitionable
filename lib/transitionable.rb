require 'transitionable/version'
require 'active_support/concern'
require 'active_support/core_ext/object'

module Transitionable

  extend ActiveSupport::Concern

  class InvalidStateTransition < StandardError
    def initialize(from_state, to_state)
      msg = from_state ?
        "Can't transition from #{from_state} to #{to_state}." :
        "Can't transition to #{to_state}."
      super(msg)
    end
  end

  module ClassMethods
    attr_accessor :state_machines

    # This assumes states is a hash
    def transition(name, states = self::STATES, transitions = self::TRANSITIONS)
      self.state_machines ||= {}
      self.state_machines[name] = { states: states.values, transitions: transitions }
      self.state_machines[name][:states].each do |this_state|
        method_name = "#{this_state}?".to_sym
        raise 'Method already defined' if self.instance_methods(false).include?(method_name)
        define_method method_name do
          current_state_based_on(this_state) == this_state
        end
      end
    end
  end

  def validate_transition!(target_state:)
    current_state = current_state_based_on(target_state)
    unless validate_transition(target_state: target_state)
      raise InvalidStateTransition.new(current_state, target_state)
    end
    true
  end

  def validate_transition(target_state:)
    self.class.state_machines.each do |machine_name, machine|
      next unless machine[:states].include?(target_state)
      current_state = send(machine_name)
      matched_transition = machine[:transitions].detect do |transition|
        transition[:from] == current_state && transition[:to] == target_state
      end
      return true if matched_transition.present?
      yield(InvalidStateTransition.new(current_state, target_state)) if block_given?
      return false
    end
    # raise error if can't find the provided target state
    raise InvalidStateTransition.new(nil, target_state)
  end

  private

  def current_state_based_on(target_state)
    self.class.state_machines.each do |machine_name, machine|
      return send(machine_name) if machine[:states].include?(target_state)
    end
    raise InvalidStateTransition.new(nil, target_state)
  end

end
