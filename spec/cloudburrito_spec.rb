require_relative '../cloudburrito'
require 'rspec'
require 'rack/test'

RSpec.describe 'The CloudBurrito app' do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    Package.delete_all
    Patron.delete_all
  end

  def token
    CloudBurrito.slack_veri_token
  end

  context 'GET /' do
    it 'returns text/plain' do
      header 'Accept', 'text/plain'
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('Welcome to Cloud Burrito!')
    end

    it 'returns text/html' do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).not_to eq('Welcome to Cloud Burrito!')
    end
  end

  context 'GET /notaburrito' do
    it 'returns 404 with text/plain' do
      header 'Accept', 'text/plain'
      get '/notaburrito'
      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq('404: Burrito Not Found!')
    end

    it 'returns 404 with text/html' do
      get '/notaburrito'
      expect(last_response.status).to eq(404)
      expect(last_response.body).not_to eq('404: Burrito Not Found!')
    end
  end

  context 'GET /stats' do
    it 'returns text/html' do
      get '/stats'
      expect(last_response).to be_ok
    end

    it 'returns application/json' do
      header 'Accept', 'application/json'
      get '/stats'
      expect(last_response).to be_ok
      x = JSON.parse last_response.body
      expect(x['ok']).to be true
    end
  end

  context 'GET /rules' do
    it 'returns text/html' do
      get '/rules'
      expect(last_response).to be_ok
    end
  end

  context 'GET /cbtp' do
    it 'returns text/html' do
      get '/cbtp'
      expect(last_response).to be_ok
    end
  end

  context 'GET /slack' do
    it 'requires user_id' do
      get '/slack'
      expect(last_response.status).to eq(401)
    end

    it 'requires token' do
      get '/slack', user_id: 1
      expect(last_response.status).to eq(401)
    end

    it 'returns 404' do
      get '/slack', token: token, user_id: 1
      expect(last_response.status).to eq(404)
    end
  end

  context 'POST /slack' do
    it 'requires user_id' do
      post '/slack'
      expect(last_response.status).to eq(401)
    end

    it 'requires token' do
      post '/slack', user_id: '1'
      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq('401: Burrito Unauthorized!')
    end

    context 'new user' do
      it 'users automatically added' do
        post '/slack', token: token, user_id: '1', text: ''
        expect(Patron.count).to eq(1)
      end

      it 'gets welcome page' do
        post '/slack', token: token, user_id: '1', text: ''
        expect(last_response).to be_ok
        expect(last_response.body).to eq("Welcome to the Cloud Burrito, where all your delicious dreams come true!
Now that you're here, you'll need to know how this works.
To join the Cloud Burrito type:
>/cloudburrito join
Once you are in the Cloud Burrito you will need to wait an hour before you can request a burrito, which you can do by typing in the following:
>/cloudburrito feed
A random person in the Cloud Burrito pool party will be selected to bring you a burrito, once you have received the burrito, you must acknowledge by typing in the following:
>/cloudburrito full
If you receive a request to bring someone a burrito you will need to acknowledge by typing:
>/cloudburrito serving
If you need a reminder of these commands, just type in:
>/cloudburrito
And that's it! Have fun!

Check out https://cloudburrito.jacksonargo.com/ for current stats!\n")
      end
    end

    context 'help' do
      it 'returns help by default' do
        create(:patron, slack_user_id: '1')
        post '/slack', token: token, user_id: '1'
        expect(last_response).to be_ok
        expect(last_response.body).to eq("Welcome to Cloud Burrito!
Version: #{`git describe`}

You can use these commands to do things:
>*join*: Join the burrito pool party.
>*leave*: Leave the burrito pool party.
>*pool*: Change your pool party.
>*feed*: Download a burrito from the cloud.
>*full*: ACK receipt of burrito.
>*status*: Where is my burrito at?
>*serving*: ACK a delivery request.
>*reject*: Reject a delivery request.
>*stats*: View your burrito stats.

Bugs? Issues? Features? Please see the link below.
https://github.com/jacksonargo/cloudburrito/issues/new
")
      end
    end

    context 'passes to slack controller' do
      let(:patron) { create(:slack_patron) }
      let(:params) { { token: token, user_id: patron.slack_user_id } }
      after(:each) do
        post '/slack', params
        expect(last_response).to be_ok
        expect(last_response.body).not_to match(/Cloud Burrito/)
      end

      it('join')    { params['text'] = 'join' }
      it('leave')   { params['text'] = 'leave' }
      it('feed')    { params['text'] = 'feed' }
      it('full')    { params['text'] = 'full' }
      it('status')  { params['text'] = 'status' }
      it('serving') { params['text'] = 'serving' }
      it('stats')   { params['text'] = 'stats' }
    end
  end

  context 'GET /user' do
    let(:patron) { create(:slack_patron) }
    it 'returns 401 without id' do
      get '/user'
      expect(last_response.status).to eq(401)
    end

    it 'returns 401 without token' do
      get '/user', id: patron._id
      expect(last_response.status).to eq(401)
    end

    it 'Can access user pages' do
      get '/user', token: patron.user_token, id: patron._id
      expect(last_response).to be_ok
    end
  end
end
