RSpec.describe Transitionable do

  before(:context) do
    class MultiEvent
      attr_accessor :delivery_state, :prep_state

      DELIVERY_STATES = {
        STAGED:    'staged',
        STARTED:   'started',
        COMPLETED: 'completed'
      }.freeze

      PREP_STATES = {
        WAITING: 'waiting',
        COOKING: 'cooking',
        COOKED:  'cooked'
      }.freeze

      DELIVERY_TRANSITIONS = [
        { from: DELIVERY_STATES[:STAGED], to: DELIVERY_STATES[:STARTED] },
        { from: DELIVERY_STATES[:STARTED], to: DELIVERY_STATES[:COMPLETED] }
      ].freeze

      PREP_TRANSITIONS = [
        { from: PREP_STATES[:WAITING], to: PREP_STATES[:COOKING] },
        { from: PREP_STATES[:COOKING], to: PREP_STATES[:COOKED] }
      ]

      include Transitionable
      transition :delivery_state, DELIVERY_STATES, DELIVERY_TRANSITIONS
      transition :prep_state, PREP_STATES, PREP_TRANSITIONS

      def initialize(delivery_state = nil, prep_state = nil)
        self.delivery_state = delivery_state
        self.prep_state = prep_state
      end
    end
  end

  after(:context) do
    Object.send(:remove_const, MultiEvent) if Object.constants.include?(MultiEvent)
  end

  describe 'multi machine helpers' do
    let(:event) { MultiEvent.new }
    it 'defines helpers for all states' do
      event.delivery_state = MultiEvent::DELIVERY_STATES[:STAGED]
      expect(event).to be_staged
      expect(event).not_to be_started
      expect(event).not_to be_completed

      event.delivery_state = MultiEvent::DELIVERY_STATES[:STARTED]
      expect(event).not_to be_staged
      expect(event).to be_started
      expect(event).not_to be_completed

      event.delivery_state = MultiEvent::DELIVERY_STATES[:COMPLETED]
      expect(event).not_to be_staged
      expect(event).not_to be_started
      expect(event).to be_completed

      event.prep_state = MultiEvent::PREP_STATES[:WAITING]
      expect(event).to be_waiting
      expect(event).not_to be_cooking
      expect(event).not_to be_cooked

      event.prep_state = MultiEvent::PREP_STATES[:COOKING]
      expect(event).not_to be_waiting
      expect(event).to be_cooking
      expect(event).not_to be_cooked

      event.prep_state = MultiEvent::PREP_STATES[:COOKED]
      expect(event).not_to be_waiting
      expect(event).not_to be_cooking
      expect(event).to be_cooked
    end
  end

  describe '#validate_transition for multi machines' do
    it 'returns false for invalid transitions' do
      event = MultiEvent.new(MultiEvent::DELIVERY_STATES[:STAGED], MultiEvent::PREP_STATES[:COOKING])
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:STAGED])).to be false
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:COMPLETED])).to be false
      expect(event.validate_transition(target_state: MultiEvent::PREP_STATES[:WAITING])).to be false
      expect(event.validate_transition(target_state: MultiEvent::PREP_STATES[:COOKING])).to be false

      event.delivery_state = MultiEvent::DELIVERY_STATES[:STARTED]
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:STAGED])).to be false
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:STARTED])).to be false

      event.delivery_state = MultiEvent::DELIVERY_STATES[:COMPLETED]
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:STAGED])).to be false
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:STARTED])).to be false

      event.prep_state = MultiEvent::PREP_STATES[:WAITING]
      expect(event.validate_transition(target_state: MultiEvent::PREP_STATES[:WAITING])).to be false
      expect(event.validate_transition(target_state: MultiEvent::PREP_STATES[:COOKED])).to be false
    end

    it 'returns true for valid transitions' do
      event = MultiEvent.new(MultiEvent::DELIVERY_STATES[:STAGED], MultiEvent::PREP_STATES[:COOKING])
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:STARTED])).to be true
      expect(event.validate_transition(target_state: MultiEvent::PREP_STATES[:COOKED])).to be true

      event.delivery_state = MultiEvent::DELIVERY_STATES[:STARTED]
      expect(event.validate_transition(target_state: MultiEvent::DELIVERY_STATES[:COMPLETED])).to be true

      event.prep_state = MultiEvent::PREP_STATES[:WAITING]
      expect(event.validate_transition(target_state: MultiEvent::PREP_STATES[:COOKING])).to be true
    end
  end

  describe '#validate_transition!' do
    let(:event) { MultiEvent.new(MultiEvent::DELIVERY_STATES[:STAGED], MultiEvent::PREP_STATES[:WAITING]) }

    it 'returns true when transition is valid,' do
      expect(event.validate_transition!(target_state: 'started')).to be true
      expect(event.validate_transition!(target_state: 'cooking')).to be true
    end

    it 'raises exception when transition is invalid' do
      expect{ event.validate_transition!(target_state: 'completed') }
        .to raise_exception(Transitionable::InvalidStateTransition, 'Can\'t transition from staged to completed.')

      expect{ event.validate_transition!(target_state: 'cooked') }
        .to raise_exception(Transitionable::InvalidStateTransition, 'Can\'t transition from waiting to cooked.')
    end

    it 'raises exception when target state is invalid,' do
      expect{ event.validate_transition!(target_state: 'foo') }
        .to raise_exception(Transitionable::InvalidStateTransition, 'Can\'t transition to foo.')
    end
  end

end
