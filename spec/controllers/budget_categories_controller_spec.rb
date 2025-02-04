require 'rails_helper'

RSpec.describe BudgetCategoriesController, type: :controller do
  let(:family) { create(:family) }
  let(:user) { create(:user, family: family) }
  let(:budget) { create(:budget, family: family) }
  let(:category) { create(:category, family: family) }
  let(:budget_category) { create(:budget_category, budget: budget, category: category) }

  before do
    sign_in(user)
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      it 'updates the budgeted_spending' do
        patch :update, params: { 
          id: budget_category.id, 
          budget_id: budget.id, 
          budget_category: { budgeted_spending: 100.0 }
        }

        expect(budget_category.reload.budgeted_spending).to eq(100.0)
        expect(response).to redirect_to(budget_budget_categories_path(budget))
      end

      it 'sets budgeted_spending to 0.0 when blank' do
        patch :update, params: { 
          id: budget_category.id, 
          budget_id: budget.id, 
          budget_category: { budgeted_spending: '' }
        }

        expect(budget_category.reload.budgeted_spending).to eq(0.0)
        expect(response).to redirect_to(budget_budget_categories_path(budget))
      end

      it 'sets budgeted_spending to 0.0 when nil' do
        patch :update, params: { 
          id: budget_category.id, 
          budget_id: budget.id, 
          budget_category: { budgeted_spending: nil }
        }

        expect(budget_category.reload.budgeted_spending).to eq(0.0)
        expect(response).to redirect_to(budget_budget_categories_path(budget))
      end
    end

    context 'with invalid parameters' do
      it 'renders show with unprocessable_entity status when validation fails' do
        patch :update, params: { 
          id: budget_category.id, 
          budget_id: budget.id, 
          budget_category: { budgeted_spending: 'invalid' }
        }

        expect(response).to render_template(:show)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
