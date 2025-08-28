require 'rails_helper'

RSpec.describe Debt, type: :model do
  describe 'scopes' do
    let!(:pending_debt) { create(:debt, status: 'pending') }
    let!(:paid_debt) { create(:debt, :paid) }
    let!(:overdue_debt) { create(:debt, :overdue) }
    let!(:future_pending_debt) { create(:debt, debt_due_date: 1.month.from_now, status: 'pending') }

    describe '.pending' do
      it 'returns only pending debts' do
        expect(Debt.pending).to include(pending_debt, future_pending_debt, overdue_debt)
        expect(Debt.pending).not_to include(paid_debt)
      end
    end

    describe '.paid' do
      it 'returns only paid debts' do
        expect(Debt.paid).to include(paid_debt)
        expect(Debt.paid).not_to include(pending_debt, future_pending_debt, overdue_debt)
      end
    end

    describe '.overdue' do
      it 'returns only overdue debts' do
        expect(Debt.overdue).to include(overdue_debt)
        expect(Debt.overdue).not_to include(pending_debt, paid_debt, future_pending_debt)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:debt)).to be_valid
    end

    it 'has a valid paid factory' do
      expect(build(:debt, :paid)).to be_valid
    end

    it 'has a valid overdue factory' do
      expect(build(:debt, :overdue)).to be_valid
    end
  end
end
