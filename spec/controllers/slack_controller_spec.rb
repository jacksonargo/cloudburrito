require_relative '../../controllers/slack_controller'
require 'rspec'

ENV['RACK_ENV'] = 'test'
Mongoid.load!('config/mongoid.yml')

describe 'The SlackController class' do
  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Package.delete_all
    Message.delete_all
  end

  let(:patron) { Patron.create user_id: '1' }
  let(:params) { { 'user_id' => patron.user_id } }
  let(:controller) { SlackController.new params }

  context '#initialize' do
    it 'creates dne patron' do
      SlackController.new 'user_id' => '2'
      expect(Patron.last).to eq Patron.find('2')
    end
    it 'set params' do
      expect(controller.params).to eq(params)
    end
    it 'set patron' do
      expect(controller.patron).to eq(patron)
    end
    it 'allows required actions' do
      expect(controller.actions).to eq(%w[feed serving full status join stats leave])
    end
  end

  context '#status' do
    it 'knows when there isnt a burrito' do
      expect(controller.status).to eq "You don't have any in coming burritos."
    end
    it 'knows when delivery isnt acked' do
      Package.create hungry_man: patron
      expect(controller.status).to eq 'You burrito is still in the fridge.'
    end
    it 'knows when burrito should be coming' do
      Package.create hungry_man: patron, en_route: true
      expect(controller.status).to eq "This burrito is on it's way!"
    end
  end

  context '#feed' do
    let(:other) { Patron.create user_id: '2' }
    context 'patron cannot feed' do
      it 'patron must be active' do
        controller.patron.is_active = false
        expect(controller.feed).to eq('Please join the pool.')
      end
      it 'patron cant be on delivery' do
        patron.active!
        Package.create hungry_man: other, delivery_man: patron
        expect(controller.feed).to eq('*You* should be delivering a burrito!')
      end
      it 'patron cant be waiting' do
        patron.active!
        Package.create hungry_man: patron, delivery_man: other
        expect(controller.feed).to eq('You already have a burrito coming!')
      end
      it 'patron cant be greedy' do
        patron.active!
        expect(patron.greedy?).to be true
        expect(controller.feed).to eq("Stop being so greedy! Wait #{patron.time_until_hungry}s.")
      end
    end
    context 'patron can feed' do
      before(:each) do
        patron.active!
        patron.force_not_greedy = true
        patron.save
      end
      it 'tells patron we are preparing his burrito' do
        expect(controller.feed).to eq('Our chefs are hard at work to prepare your burrito!')
      end
      it 'creates a burrito for patron' do
        controller.feed
        expect(Package.count).to eq 1
      end
      it 'patron is now waiting for burrito' do
        controller.feed
        expect(patron.waiting?).to be true
      end
      it 'patron incoming burrito matches the new burrito' do
        controller.feed
        expect(patron.incoming_burrito).to eq Package.first
      end
    end
  end

  context '#stats' do
    it 'returns url to check stats' do
      expect(controller.stats).not_to be_empty
    end
    it 'returns unique url' do
      expect(controller.stats).not_to eq(controller.stats)
    end
  end

  context '#join' do
    it 'checks if patron is active' do
      controller.patron.active!
      expect(controller.join).to eq("You are already part of the pool party!\nRequest a burrito with */cloudburrito feed*.")
    end
    it 'activated inactive patron' do
      expect(controller.join).to eq('Please enjoy our fine selection of burritos!')
      expect(controller.patron.active?).to be true
    end
  end

  context '#leave' do
    it 'marks a patron as inactive' do
      expect(controller.leave).to eq('You have left the burrito pool party.')
      expect(controller.patron.active?).to eq(false)
    end
  end

  context '#serving' do
    let(:other) { Patron.create user_id: '2' }
    context 'patron is not on a delivery' do
      it 'tells them they arent delivering' do
        expect(controller.serving).to eq("You haven't been volunteered to deliver...")
      end
    end
    context 'package is already acked' do
      it 'tells patron this package is acked' do
        Package.create en_route: true, hungry_man: other, delivery_man: patron
        expect(controller.serving).to eq("You've already acked this request...")
      end
    end
    context 'patron needs to ack' do
      before(:each) do
        Package.create hungry_man: other, delivery_man: patron
      end
      it 'tells patron to make haste' do
        expect(controller.serving).to eq('Make haste!')
      end
      it 'marks package as en_route' do
        controller.serving
        package = Package.first
        expect(package.en_route).to be true
      end
    end
  end

  context '#full' do
    let(:dman) { Patron.create user_id: '2' }
    context 'patron does not have incoming burritos' do
      it 'tells them to order a burrito' do
        expect(controller.full).to eq("You don't have any incoming burritos. Order one with: */cloudburrito feed*")
      end
    end
    context 'patron has incoming burritos' do
      before(:each) do
        Package.create hungry_man: patron, delivery_man: dman
      end
      it 'tells patron to enjoy' do
        expect(controller.full).to eq 'Enjoy!'
      end
      it 'marks package as received' do
        controller.full
        package = Package.first
        expect(package.received).to be true
      end
      it 'patron is no longer waiting' do
        controller.full
        expect(patron.waiting?).to be false
      end
      it 'patron is now greedy' do
        controller.full
        expect(patron.greedy?).to be true
      end
      it 'delivery man is no longer on delivery' do
        controller.full
        expect(dman.on_delivery?).to be false
      end
      it 'delivery man is now sleep' do
        controller.full
        expect(dman.sleepy?).to be true
      end
      context 'creates a message for delivery man' do
        before(:each) { controller.full }
        it 'and message exists.' do
          expect(Message.last).not_to be nil
        end
        it 'and is assigned to delivery man.' do
          expect(Message.last.to).to eq dman
        end
        it 'and says you can order.' do
          text = 'Your delivery has been acked. You can request more burritos!'
          expect(Message.last.text).to eq text
        end
      end
    end
  end
end
