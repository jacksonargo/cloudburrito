require_relative '../lib/events'
require 'rspec'
require 'rack/test'

describe "Event manager" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Package.delete_all
  end

  let(:events) { Events.new }
  let(:hman) { Patron.create user_id: '1' }

  context '#start' do
    it 'creates a thread' do
      events.start
    end

    it 'assigns all unassigned packages' do
      # Create patrons to be assigned as delivery men
      (2..11).each {|x| Patron.create user_id: x.to_s, is_active: true }
      Package.create hungry_man: hman
      Package.create hungry_man: Patron.find('2')
      Package.create hungry_man: Patron.find('3')
      events.start
      events.wait_for_complete
      expect(events.unassigned_packages.count).to eq 0
    end
  end

  context '#unassigned_packages' do
    it 'returns unassigned packages' do
      (1..10).each { Package.create hungry_man: hman }
      expect(events.unassigned_packages.count).to eq(10)
    end
  end

  context '#get_delivery_man' do
    it 'is nil if none are eligible' do
      expect(events.get_delivery_man).to be nil
    end
    it 'returns new active dman' do
      dman = Patron.create user_id: '2', is_active: true
      expect(events.get_delivery_man).to eq dman
    end
  end

  context '#assign_next' do
    it 'assigns packages' do
      Package.create hungry_man: hman
      Patron.create user_id: '2', is_active: true
      events.assign_next
      expect(events.unassigned_packages.count).to eq(0)
    end
    it 'assigns packages first in first out' do
      # Create patron
      p2 = Patron.create user_id: '2'
      p3 = Patron.create user_id: '3', is_active: true
      # Create two packages
      b1 = Package.create hungry_man: hman
      b2 = Package.create hungry_man: p2
      events.assign_next
      b1.reload
      b2.reload
      expect(b1.assigned?).to be true
      expect(b2.assigned?).to be false
    end
  end

  context '#get_stale_packages' do
  end

  context '#replace_stale_package' do
  end
end
