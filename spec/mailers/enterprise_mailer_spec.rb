# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnterpriseMailer do
  let!(:enterprise) { create(:enterprise) }
  let!(:user) { create(:user) }

  describe "#welcome" do
    it "sends a welcome email when given an enterprise" do
      EnterpriseMailer.welcome(enterprise).deliver_now

      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject)
        .to eq "#{enterprise.name} is now on #{Spree::Config[:site_name]}"
    end

    it "does not set a reply-to email" do
      EnterpriseMailer.welcome(enterprise).deliver_now
      expect(ActionMailer::Base.deliveries.first.reply_to).to be nil
    end
  end

  describe "#manager_invitation" do
    it "should send a manager invitation email when given an enterprise and user" do
      EnterpriseMailer.manager_invitation(enterprise, user).deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq "#{enterprise.name} has invited you to be a manager"
    end

    it "sets a reply-to of the enterprise email" do
      EnterpriseMailer.manager_invitation(enterprise, user).deliver_now
      expect(ActionMailer::Base.deliveries.first.reply_to).to eq([enterprise.contact.email])
    end
  end
end
