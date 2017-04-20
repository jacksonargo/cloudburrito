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
    context 'assigns packages first in first out' do
      before(:each) do
        # Create patrons
        p2 = Patron.create user_id: '2'
        p3 = Patron.create user_id: '3', is_active: true
        # Create two packages
        b1 = Package.create hungry_man: hman
        b2 = Package.create hungry_man: p2
        events.assign_next
        b1.reload
        b2.reload
      end
      it 'first package is assigned' do
        expect(b1.assigned?).to be true
      end
      it 'second package is unassigned' do
        expect(b2.assigned?).to be false
      end
    end
  end

  context '#get_stale_packages' do
    let(:dman) { Patron.create user_id: '2' }
    it 'returns [] when there are no packages' do
      expect(events.get_stale_packages).to eq []
    end
    it 'returns [] when no stale packages' do
      p = Package.create hungry_man: hman
      p.assign! dman
      expect(events.get_stale_packages).to eq []
    end
    it 'returns stale packages' do
      p = Package.create hungry_man: hman
      p.assign! dman
      p.stale!
      expect(events.get_stale_packages.first).to eq p
    end
  end

  context '#replace' do
    let(:package) { Package.create hungry_man: hman }
    it 'marks the package as failed' do
      events.replace package
      expect(package.failed?).to eq true
    end
    it 'creates a new package for hungry_man' do
      events.replace package
      expect(Package.count).to eq 2
      expect(Package.last.hungry_man).to eq hman
    end
  end

  context '#replace_stale_packages' do
    it 'replaces all stale packages' do
      p1 = Package.create hungry_man: hman
      p2 = Package.create hungry_man: hman
      p1.stale!
      p2.stale!
      events.replace_stale_packages
      expect(Package.count).to eq 4
    end
  end

   context '#stop' do
    it 'stops the thread' do
      events.start
      events.stop
      expect(events.thread.alive?).to be false
    end
  end

  context '#start' do
    it 'creates a thread' do
      events.start
      expect(events.thread.alive?).to be true
      events.stop
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
      events.stop
    end
  end

  context '#wait_for_complete' do
    it 'returns when no more stale packages' do
      events.start
      events.wait_for_complete
      expect(events.get_stale_packages).to eq []
      events.stop
    end
    it 'returns when no more unassigned packages' do
      events.start
      events.wait_for_complete
      expect(events.unassigned_packages.exists?).to eq false
      events.stop
    end
  end
end
