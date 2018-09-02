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
    it 'returns false for invalid transitions' do
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
      allow(event).to receive(:validate_transition).with(target_state: 'foo').and_return(true)
      expect(event.validate_transition!(target_state: 'foo')).to be true
    end

    it 'raises exception when transition is invalid,' do
      allow(event).to receive(:validate_transition).with(target_state: 'foo').and_return(false)
      expect{ event.validate_transition!(target_state: 'foo') }
        .to raise_exception(Transitionable::InvalidStateTransition, 'Can\'t transition from staged to foo.')
    end
  end

end
