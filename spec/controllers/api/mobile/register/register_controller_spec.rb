require 'rails_helper'

RSpec.describe Api::Mobile::Register::RegisterController, type: :controller do
  describe 'POST #login' do
    let(:user) { create(:user) }
    let(:token) { user.create_access_token.token }

    # Ensure user has a token
    before do
       user.save
    end

    context 'with valid access_token' do
      it 'logs in the user and returns success' do
        post :login, params: { access_token: user.access_token.token }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['email']).to eq(user.email)
        expect(json_response['data']['uid']).to eq(user.id)
      end
    end

    context 'with invalid access_token' do
      it 'returns unauthorized' do
        post :login, params: { access_token: 'invalid_token' }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['msg']).to eq('无效的 token')
      end
    end

    context 'without access_token' do
      it 'falls back to email/password login success' do
        post :login, params: { email: user.email, password: user.password }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['email']).to eq(user.email)
      end
      
      it 'falls back to email/password login failure' do
        post :login, params: { email: user.email, password: 'wrong_password' }
        
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
