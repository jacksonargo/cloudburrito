require_relative '../../models/patron'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Patron class' do
  let(:patron) { create(:patron) }

  before(:each) do
    Pool.delete_all
    Patron.delete_all
    Package.delete_all
  end

  context '#valid?' do
    context 'returns false when' do
      let(:patron) { build(:patron) }
      after(:each) { expect(patron.valid?).to be(false) }
      it('sleepy_time is not integer') { patron.sleepy_time = '3600' }
      it('greedy_time is not integer') { patron.greedy_time = '3600' }
      context 'slack_user is true' do
        let(:patron) { build(:patron, slack_user: true) }
        it('slack_user_id is empty') { patron.slack_user_id = nil }
      end
    end
  end

  context '#new' do
    context 'valid' do
      it 'can be created' do
        expect(patron.save).to eq(true)
      end

      context 'default' do
        it 'inactive' do
          expect(patron.active?).to be false
        end

        it 'active_at is nil' do
          expect(patron.active_at).to be nil
        end
      end

      context 'created with active true' do
        let(:patron) { create(:patron, active: true) }
        it 'active_at is not nil' do
          expect(patron.active_at).not_to be nil
        end
      end
    end

    context 'invalid' do
      context 'pool is nil' do
        let(:patron) { build(:patron, pool: nil) }
        it 'cant be saved' do
          expect(patron.save).to be false
        end
      end
    end
  end

  context '#active_delivery' do
    context 'no deliveries assigned' do
      it 'returns nil' do
        expect(patron.active_delivery).to be nil
      end
    end

    context 'deliveries have been assigned' do
      before(:each) do
        create_list(:received_pack, 15, delivery_man: patron)
      end

      context 'all packages delivered' do
        it 'returns nil' do
          expect(patron.active_delivery).to be nil
        end
      end

      context 'undelivered package exists' do
        let(:package) { create(:assigned_pack, delivery_man: patron) }
        before(:each) { package.reload }
        it 'returns active delivery' do
          expect(patron.active_delivery).to eq(package)
        end
      end
    end
  end

  context '#on_delivery?' do
    context 'no deliveries assigned' do
      it 'returns false' do
        expect(patron.on_delivery?).to be false
      end
    end

    context 'deliveries have been assigned' do
      before(:each) do
        create_list(:received_pack, 15, delivery_man: patron)
      end

      context 'all packages delivered' do
        it 'returns false' do
          expect(patron.on_delivery?).to be false
        end
      end

      context 'undelivered package exists' do
        it 'returns true' do
          create(:package, delivery_man: patron)
          expect(patron.on_delivery?).to be true
        end
      end
    end
  end

  context '#incoming_burrito' do
    context 'has no burritos' do
      it 'returns nil' do
        expect(patron.incoming_burrito).to be nil
      end
    end

    context 'has burritos' do
      before(:each) do
        create_list(:received_pack, 15, hungry_man: patron)
      end

      context 'all burritos received' do
        it 'returns nil' do
          expect(patron.incoming_burrito).to be nil
        end
      end

      context 'incoming burrito exists' do
        let(:package) { create(:package, hungry_man: patron) }
        before(:each) { package.reload }
        it 'returns incoming burrito' do
          expect(patron.incoming_burrito).to eq(package)
        end
      end
    end
  end

  context '#waiting?' do
    context 'no burritos ordered' do
      it 'returns false' do
        expect(patron.waiting?).to be false
      end
    end

    context 'no incoming burrito' do
      it 'returns false' do
        create(:received_pack, hungry_man: patron)
        expect(patron.waiting?).to be false
      end
    end

    context 'has incoming burrito' do
      it 'returns true' do
        create(:package, hungry_man: patron)
        expect(patron.waiting?).to be true
      end
    end
  end

  context '#time_of_last_burrito' do
    context 'no burritos ordered' do
      it 'returns 0' do
        expect(patron.time_of_last_burrito).to eq(Time.at(0))
      end
    end

    context 'just received burrito' do
      let(:burrito) { create(:received_pack, hungry_man: patron) }
      before(:each) { burrito.reload }
      it 'doesnt return 0' do
        expect(patron.time_of_last_burrito).not_to eq(Time.at(0))
      end

      it 'equals burrito.received_at' do
        expect(patron.time_of_last_burrito).to eq(burrito.received_at)
      end
    end
  end

  context '#time_of_last_delivery' do
    context 'no deliveries' do
      it 'returns 0' do
        expect(patron.time_of_last_delivery).to eq(Time.at(0))
      end
    end

    context 'just delivered burrito' do
      let(:delivery) { create(:received_pack, delivery_man: patron) }
      before(:each) { delivery.reload }
      it 'doesnt return 0' do
        expect(patron.time_of_last_delivery).not_to eq(Time.at(0))
      end

      it 'equals delivery.received_at' do
        expect(patron.time_of_last_delivery).to eq(delivery.received_at)
      end
    end
  end

  context '#time_until_hungry' do
  end

  context '#time_until_awake' do
  end

  context '#active!' do
    before(:each) { patron.active! }
    it 'sets active_at' do
      expect(patron.active_at).not_to be nil
    end
    it 'sets active' do
      expect(patron.active).to be true
    end
  end

  context '#active?' do
    it 'not when created' do
      expect(patron.active?).to be false
    end
    it 'when active' do
      patron.active!
      expect(patron.active?).to be true
    end
  end

  context '#inactive!' do
    before(:each) { patron.inactive! }
    it 'unsets active' do
      expect(patron.active).to eq(false)
    end
    it 'sets inactive_at' do
      expect(patron.inactive_at).not_to be nil
    end
  end

  context '#inactive?' do
    it 'when created' do
      expect(patron.inactive?).to be true
    end
    it 'not when activated' do
      patron.active!
      expect(patron.inactive?).to be false
    end
    it 'when deactivated' do
      patron.inactive!
      expect(patron.inactive?).to be true
    end
  end

  context '#sleepy?' do
    let(:package) { create(:package, delivery_man: patron) }
    it 'not when created' do
      expect(patron.sleepy?).to eq(false)
    end

    it 'after delivery' do
      package.received!
      expect(patron.sleepy?).to eq(true)
    end

    it 'not 3600s after delivery' do
      package.received!
      package.received_at = Time.now - 3600
      package.save
      expect(patron.sleepy?).to eq(false)
    end
  end

  context '#greedy?' do

    it 'not when forced not greedy' do
      patron.force_not_greedy = true
      expect(patron.greedy?).to eq(false)
    end

    context 'inactive' do
      before(:each) { patron.inactive! }
      it('is greedy') { expect(patron.greedy?).to eq(true) }
    end

    context 'active' do
      before(:each) { patron.active! }

      context 'for less than 3600 seconds' do
        before(:each) { patron.active_at = Time.now }

        context 'never delivered burrito' do
          it('is greedy') { expect(patron.greedy?).to eq(true) }
        end

        context 'delivered burrito' do
          let(:package) { create(:package, delivery_man: patron) }
          before(:each) { package.received! }

          context 'within 3600 seconds' do
            before(:each) do
              package.received_at = Time.now - 600
              package.save
            end
            context 'recevied burrito since last delivery' do
              let(:package2) { create(:package, hungry_man: patron) }
              before(:each) { package2.received! }
              it('is greedy') { expect(patron.greedy?).to eq(true) }
            end

            context 'have not received burrito since last delivery' do
              it('is not greedy') { expect(patron.greedy?).to eq(false) }
            end
          end

          context 'over 3600 seconds ago' do
            before(:each) do
              package.received_at = Time.now - 3600
              package.save
            end
            it('is greedy') { expect(patron.greedy?).to eq(true) }
          end
        end
      end

      context 'for more than 3600 seconds' do
        before(:each) { patron.active_at = Time.now - 3600 }

        context 'marked inactive' do
          before(:each) { patron.inactive! }
          it('is greedy') { expect(patron.greedy?).to eq(true) }
        end

        context 'just after receiving burrito' do
          let(:package) { create(:package, hungry_man: patron) }
          before(:each) { package.received! }
          it('is greedy') { expect(patron.greedy?).to eq(true) }
        end

        context '3600s after receiving burrito' do
          let(:package) { create(:package, hungry_man: patron) }
          before(:each) do
            patron.active_at = Time.now - 3600
            package.received!
            package.received_at = Time.now - 3600
            package.save
          end
          it('is not greedy') { expect(patron.greedy?).to eq(false) }
        end
      end
    end
  end

  context '#user_token' do
    it 'exists' do
      expect(patron.user_token).not_to be_empty
    end

    it 'is unique' do
      y = create(:patron)
      expect(patron.user_token).not_to eq(y.user_token)
    end
  end

  context '#can_deliver?' do
    it 'when active' do
      patron.active!
      expect(patron.can_deliver?).to be true
    end
    it 'not when created' do
      expect(patron.can_deliver?).to be false
    end
    it 'not if inactive' do
      patron.inactive!
      expect(patron.can_deliver?).to be false
    end
    it 'not if on delivery' do
      patron.active!
      create(:package, delivery_man: patron)
      expect(patron.can_deliver?).to be false
    end
    it 'not if sleeping after delivery' do
      patron.active!
      create(:received_pack, delivery_man: patron)
      expect(patron.can_deliver?).to be false
    end
    it 'not if waiting for a burrito' do
      patron.active!
      create(:package, hungry_man: patron)
      expect(patron.can_deliver?).to be false
    end
  end

  context '#slack_link' do
    it 'returns a link to the slack user' do
      expect(patron.slack_link).to eq "<@#{patron.slack_user_id}>"
    end
  end

  context '#slack_user_info' do
    it 'returns {} if slack_user_id is invalid' do
      expect(patron.slack_user_info).to eq Hash.new
    end
  end

  context '#slack_first_name' do
    it 'returns the name of the user in slack' do
      slack_user_id = ENV['SLACK_TEST_USER_ID'].dup
      name = ENV['SLACK_TEST_USER_NAME'].dup
      tester = create(:patron, slack_user_id: slack_user_id)
      expect(tester.slack_first_name).to eq(name)
    end
    it 'returns slack_user_id if slack_user_id is invalid' do
      expect(patron.slack_first_name).to eq(patron.slack_user_id)
    end
  end

  context '#stats_url' do
    it 'returns valid stats url' do
      stats_url = patron.stats_url
      expected_url = "https://cloudburrito.jacksonargo.com/user?id=#{patron._id}&token=#{patron.user_token}"
      expect(stats_url).to eq(expected_url)
    end
  end
end
