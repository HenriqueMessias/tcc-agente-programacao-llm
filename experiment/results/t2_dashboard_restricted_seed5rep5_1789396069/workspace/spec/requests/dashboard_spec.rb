require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  # Helper: extrai o conteúdo textual de um elemento pelo id.
  def element_text(html, id)
    doc = Nokogiri::HTML(html)
    node = doc.at_css("##{id}")
    node&.text&.strip
  end

  def element(html, id)
    Nokogiri::HTML(html).at_css("##{id}")
  end

  describe "GET /dashboard" do
    context "com pedidos existentes" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        Order.create!(amount: 200.00, category: "Roupas",      order_date: Date.new(2026, 1, 15))
        Order.create!(amount: 300.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 20))
      end

      it "retorna HTTP 200 (critério 1)" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
      end

      it "exibe o total de vendas correto (critério 2)" do
        get "/dashboard"
        expect(element_text(response.body, "metric-total")).to include("600")
      end

      it "exibe o número de pedidos correto (critério 3)" do
        get "/dashboard"
        expect(element_text(response.body, "metric-count")).to include("3")
      end

      it "exibe o ticket médio correto (critério 4)" do
        get "/dashboard"
        # 600 / 3 = 200
        expect(element_text(response.body, "metric-average")).to include("200")
      end

      it "exibe a tabela de pedidos com categoria e valor (critério 5)" do
        get "/dashboard"
        table = element(response.body, "orders-table")
        expect(table).not_to be_nil
        text = table.text
        expect(text).to include("Eletrônicos")
        expect(text).to include("Roupas")
        expect(text).to include("100")
        expect(text).to include("200")
        expect(text).to include("300")
      end

      it "exibe o gráfico com uma barra por categoria (critério 6)" do
        get "/dashboard"
        chart = element(response.body, "chart")
        expect(chart).not_to be_nil
        bars = chart.css(".chart-bar")
        expect(bars.size).to eq(2) # Eletrônicos e Roupas
      end

      it "a soma dos valores da tabela é consistente com o total (critério 10)" do
        get "/dashboard"
        table = element(response.body, "orders-table")
        values = table.css("td").map(&:text).join(" ").scan(/\d+[.,]?\d*/).map { |v| v.tr(",", ".").to_f }
        # soma dos valores presentes na tabela deve conter 600
        expect(values.sum).to be >= 600.0
        expect(element_text(response.body, "metric-total")).to include("600")
      end
    end

    context "com filtro por intervalo de datas" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        Order.create!(amount: 200.00, category: "Roupas",      order_date: Date.new(2026, 1, 15))
        Order.create!(amount: 300.00, category: "Eletrônicos", order_date: Date.new(2026, 2, 20))
      end

      it "restringe os pedidos considerados nos indicadores e na tabela (critério 7)" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        expect(response).to have_http_status(:ok)
        expect(element_text(response.body, "metric-count")).to include("2")
        expect(element_text(response.body, "metric-total")).to include("300")
        table = element(response.body, "orders-table")
        expect(table.text).not_to include("300")
      end

      it "não inclui pedidos fora do intervalo (critério 9)" do
        get "/dashboard", params: { start_date: "2026-02-01", end_date: "2026-02-28" }
        expect(element_text(response.body, "metric-count")).to include("1")
        expect(element_text(response.body, "metric-total")).to include("300")
        expect(element_text(response.body, "metric-average")).to include("300")
      end

      it "exibe o estado vazio para intervalo sem pedidos, sem erro 500 (critério 8)" do
        get "/dashboard", params: { start_date: "2020-01-01", end_date: "2020-12-31" }
        expect(response).to have_http_status(:ok)
        expect(element(response.body, "empty-state")).not_to be_nil
      end
    end

    context "sem pedidos" do
      it "exibe o estado vazio e HTTP 200 (critério 8)" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
        expect(element(response.body, "empty-state")).not_to be_nil
      end
    end

    context "contrato de DOM" do
      before do
        Order.create!(amount: 50.00, category: "Alimentos", order_date: Date.new(2026, 3, 5))
      end

      it "possui o elemento raiz #dashboard" do
        get "/dashboard"
        expect(element(response.body, "dashboard")).not_to be_nil
      end

      it "possui o formulário de filtro com os campos start_date e end_date" do
        get "/dashboard"
        form = element(response.body, "filter-form")
        expect(form).not_to be_nil
        expect(form.at_css("[name='start_date']")).not_to be_nil
        expect(form.at_css("[name='end_date']")).not_to be_nil
      end
    end
  end
end
