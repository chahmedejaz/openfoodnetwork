# frozen_string_literal: false

require 'spec_helper'

RSpec.describe Spree::Admin::SearchController do
  context "Distributor Enterprise User" do
    let!(:owner) { create(:user, email: "test1@email.com" ) }
    let!(:manager) { create(:user, email: "test2@email.com" ) }
    let!(:random) { create(:user, email: "test3@email.com" ) }
    let!(:enterprise) { create(:enterprise, owner:, users: [owner, manager]) }
    before { controller_login_as_enterprise_user [enterprise] }

    describe 'searching for known users' do
      describe "when search query is not an exact match" do
        before do
          spree_get :known_users, q: "test"
        end

        it "returns a list of users that I share management of enteprises with" do
          expect(assigns(:users)).to include owner, manager
          expect(assigns(:users)).not_to include random
        end
      end

      describe "when search query exactly matches the email of a user in the system" do
        before do
          spree_get :known_users, q: "test3@email.com"
        end

        it "returns that user, regardless of the relationship between the two users" do
          expect(assigns(:users)).to eq [random]
        end
      end
    end

    describe 'searching for customers' do
      let!(:customer1) { create(:customer, enterprise:, email: 'test1@email.com') }
      let!(:customer2) { create(:customer, enterprise:, first_name: 'test2') }
      let!(:customer3) { create(:customer, email: 'test3@email.com') }

      describe 'when search owned enterprises' do
        before do
          spree_get :customers, q: "test", distributor_id: enterprise.id
          @results = response.parsed_body
        end

        describe 'when search query matches the email or name' do
          it 'returns a list of customers of the enterprise' do
            expect(@results.size).to eq 2

            expect(@results.find { |c| c['id'] == customer1.id }).to be_truthy
            expect(@results.find { |c| c['id'] == customer2.id }).to be_truthy
          end

          it 'does not return the customer of other enterprises' do
            expect(@results.find { |c| c['id'] == customer3.id }).to be_nil
            p customer3
            p enterprise
          end
        end
      end

      describe 'when search in unmanaged enterprise' do
        before do
          spree_get :customers, q: "test", distributor_id: customer3.enterprise_id
          @results = response.parsed_body
        end

        it 'returns empty array' do
          expect(@results).to eq []
        end
      end
    end
  end
end
