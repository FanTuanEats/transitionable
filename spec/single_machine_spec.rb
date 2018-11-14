RSpec.describe Transitionable do

  before(:context) do
    class Event
      attr_accessor :some_state

      STATES = {
        STAGED:    'staged',
        STARTED:   'started',
        COMPLETED: 'completed'
      }.freeze

      TRANSITIONS = [
        { from: STATES[:STAGED], to: STATES[:STARTED] },
        { from: STATES[:STARTED], to: STATES[:COMPLETED] }
      ].freeze

      include Transitionable
      transition :some_state

      def initialize(state = nil)
        self.some_state = state
      end
    end
  end

  after(:context) do
    Object.send(:remove_const, Event) if Object.constants.include?(Event)
  end

  describe 'helpers' do
    let(:event) { Event.new }
    it 'defines helpers for all states' do
      event.some_state = Event::STATES[:STAGED]
      expect(event).to be_staged
      expect(event).not_to be_started
      expect(event).not_to be_completed

      event.some_state = Event::STATES[:STARTED]
      expect(event).not_to be_staged
      expect(event).to be_started
      expect(event).not_to be_completed

      event.some_state = Event::STATES[:COMPLETED]
      expect(event).not_to be_staged
      expect(event).not_to be_started
      expect(event).to be_completed
    end
  end

  describe '#validate_transition' do
    context 'when transaction is invalid,' do
      it 'returns false' do
        event = Event.new(Event::STATES[:STAGED])
        expect(event.validate_transition(target_state: Event::STATES[:STAGED])).to be false
        expect(event.validate_transition(target_state: Event::STATES[:COMPLETED])).to be false

        event.some_state = Event::STATES[:STARTED]
        expect(event.validate_transition(target_state: Event::STATES[:STAGED])).to be false
        expect(event.validate_transition(target_state: Event::STATES[:STARTED])).to be false

        event.some_state = Event::STATES[:COMPLETED]
        expect(event.validate_transition(target_state: Event::STATES[:STAGED])).to be false
        expect(event.validate_transition(target_state: Event::STATES[:STARTED])).to be false
      end

      it 'yields error if block is given' do
        event = Event.new(Event::STATES[:STAGED])
        error = nil
        expect(
          event.validate_transition(target_state: Event::STATES[:STAGED]) do |err|
            error = err
          end
        ).to be false
        expect(error.message).to eq 'Can\'t transition from staged to staged.'
      end
    end

    it 'returns true for valid transitions' do
      event = Event.new(Event::STATES[:STAGED])
      expect(event.validate_transition(target_state: Event::STATES[:STARTED])).to be true

      event.some_state = Event::STATES[:STARTED]
      expect(event.validate_transition(target_state: Event::STATES[:COMPLETED])).to be true
    end
  end

  describe '#validate_transition!' do
    let(:event) { Event.new(Event::STATES[:STAGED]) }

    it 'returns true when transition is valid,' do
      expect(event.validate_transition!(target_state: 'started')).to be true
    end

    it 'raises exception when transition is invalid' do
      expect{ event.validate_transition!(target_state: 'completed') }
        .to raise_exception(Transitionable::InvalidStateTransition, 'Can\'t transition from staged to completed.')
    end

    it 'raises exception when target state is invalid,' do
      expect{ event.validate_transition!(target_state: 'foo') }
        .to raise_exception(Transitionable::InvalidStateTransition, 'Can\'t transition to foo.')
    end
  end

end
