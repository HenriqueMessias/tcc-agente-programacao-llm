require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  def create_order(amount:, category:, order_date:)
    Order.create!(amount: amount, category: category, order_date: order_date)
  end

  describe "GET /dashboard" do
    context "com pedidos existentes" do
      before do
        create_order(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        create_order(amount: 200.00, category: "Livros",      order_date: Date.new(2026, 1, 15))
        create_order(amount: 300.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 20))
      end

      it "retorna HTTP 200 (critério 1)" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
      end

      it "exibe o elemento raiz #dashboard" do
        get "/dashboard"
        expect(response.body).to include('id="dashboard"')
      end

      it "exibe o total de vendas correto (critério 2)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-total"')
        expect(response.body).to match(/id="metric-total"[^>]*data-value="600(\.0+)?"/)
      end

      it "exibe o número de pedidos correto (critério 3)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-count"')
        expect(response.body).to match(/id="metric-count"[^>]*data-value="3"/)
      end

      it "exibe o ticket médio correto (critério 4)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-average"')
        expect(response.body).to match(/id="metric-average"[^>]*data-value="200(\.0+)?"/)
      end

      it "exibe a tabela de pedidos com categoria e valor (critério 5)" do
        get "/dashboard"
        expect(response.body).to include('id="orders-table"')
        expect(response.body).to include("Eletrônicos")
        expect(response.body).to include("Livros")
      end

      it "exibe o gráfico com um elemento por categoria (critério 6)" do
        get "/dashboard"
        expect(response.body).to include('id="chart"')
        bars = response.body.scan(/class="chart-bar"/).size
        expect(bars).to eq(2) # Eletrônicos e Livros
      end

      it "não exibe o estado vazio quando há pedidos" do
        get "/dashboard"
        expect(response.body).not_to include('id="empty-state"')
      end
    end

    context "com filtro por intervalo de datas" do
      before do
        create_order(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        create_order(amount: 200.00, category: "Livros",      order_date: Date.new(2026, 1, 15))
        create_order(amount: 300.00, category: "Eletrônicos", order_date: Date.new(2026, 2, 20))
      end

      it "restringe os indicadores e a tabela ao período (critérios 7 e 9)" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/id="metric-total"[^>]*data-value="300(\.0+)?"/)
        expect(response.body).to match(/id="metric-count"[^>]*data-value="2"/)
        expect(response.body).to match(/id="metric-average"[^>]*data-value="150(\.0+)?"/)
      end

      it "exclui pedidos fora do intervalo (critério 9)" do
        get "/dashboard", params: { start_date: "2026-02-01", end_date: "2026-02-28" }
        expect(response.body).to match(/id="metric-total"[^>]*data-value="300(\.0+)?"/)
        expect(response.body).to match(/id="metric-count"[^>]*data-value="1"/)
      end

      it "exibe o formulário de filtro com os campos esperados" do
        get "/dashboard"
        expect(response.body).to include('id="filter-form"')
        expect(response.body).to include('name="start_date"')
        expect(response.body).to include('name="end_date"')
      end

      it "a soma dos valores da tabela é consistente com o total (critério 10)" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        values = response.body.scan(/data-amount="([\d.]+)"/).flatten.map(&:to_f)
        expect(values.sum).to eq(300.0)
      end
    end

    context "com intervalo sem pedidos" do
      before do
        create_order(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
      end

      it "exibe o estado vazio sem erro HTTP 500 (critério 8)" do
        get "/dashboard", params: { start_date: "2030-01-01", end_date: "2030-01-31" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="empty-state"')
      end

      it "zera os indicadores no estado vazio" do
        get "/dashboard", params: { start_date: "2030-01-01", end_date: "2030-01-31" }
        expect(response.body).to match(/id="metric-count"[^>]*data-value="0"/)
        expect(response.body).to match(/id="metric-total"[^>]*data-value="0(\.0+)?"/)
      end
    end

    context "sem nenhum pedido cadastrado" do
      it "exibe o estado vazio sem erro (critério 8)" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="empty-state"')
      end
    end
  end
end
