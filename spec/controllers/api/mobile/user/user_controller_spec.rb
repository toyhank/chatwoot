require 'rails_helper'

RSpec.describe Api::Mobile::User::UserController, type: :controller do
  describe 'DELETE #delete' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    
    # Ensure users have access tokens
    before do
      user.save
      other_user.save
    end

    context 'with valid Bearer token' do
      it 'deletes the user and returns success' do
        token = user.access_token.token
        request.headers['Authorization'] = "Bearer #{token}"
        
        expect { delete :delete }.to change(User, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(200)
        expect(json_response['msg']).to eq('账户删除成功')
        expect(json_response['data']).to be_nil
        
        # Verify user is actually deleted
        expect(User.find_by(id: user.id)).to be_nil
      end

      it 'deletes all user associated data' do
        token = user.access_token.token
        
        # Create some associated data
        account = create(:account)
        account_user = create(:account_user, user: user, account: account)
        
        request.headers['Authorization'] = "Bearer #{token}"
        
        delete :delete
        
        expect(response).to have_http_status(:ok)
        expect(User.find_by(id: user.id)).to be_nil
      end

      it 'does not affect other users\' data' do
        token = user.access_token.token
        other_user_id = other_user.id
        
        request.headers['Authorization'] = "Bearer #{token}"
        
        expect { delete :delete }.to change(User, :count).by(-1)
        
        # Other user should still exist
        expect(User.find_by(id: other_user_id)).to be_present
      end
    end

    context 'with invalid Bearer token' do
      it 'returns unauthorized with invalid token' do
        request.headers['Authorization'] = 'Bearer invalid_token_xyz'
        
        expect { delete :delete }.not_to change(User, :count)
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(401)
        expect(json_response['msg']).to eq('未授权,请先登录')
      end

      it 'returns unauthorized with missing Authorization header' do
        expect { delete :delete }.not_to change(User, :count)
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(401)
        expect(json_response['msg']).to eq('未授权,请先登录')
      end

      it 'returns unauthorized with malformed Authorization header' do
        request.headers['Authorization'] = 'InvalidFormat token123'
        
        expect { delete :delete }.not_to change(User, :count)
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(401)
      end
    end

    context 'with deleted user token' do
      it 'returns unauthorized when trying to delete again' do
        token = user.access_token.token
        
        # First deletion
        request.headers['Authorization'] = "Bearer #{token}"
        delete :delete
        expect(response).to have_http_status(:ok)
        
        # Try to delete again with the same token
        delete :delete
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(401)
        expect(json_response['msg']).to eq('未授权,请先登录')
      end
    end
  end
end
