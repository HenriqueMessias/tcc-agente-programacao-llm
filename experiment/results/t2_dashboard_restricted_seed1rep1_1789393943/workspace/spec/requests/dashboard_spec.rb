require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  # Helper: extrai o texto de um elemento pelo id, removendo tags e normalizando espaços.
  def element_text(html, id)
    doc = Nokogiri::HTML(html)
    node = doc.at_css("##{id}")
    return nil if node.nil?
    node.text.gsub(/\s+/, " ").strip
  end

  # Helper: converte um texto monetário/número em Float.
  def to_number(text)
    text.to_s.gsub(/[^\d,.\-]/, "").tr(",", ".").to_f
  end

  describe "GET /dashboard" do
    context "com pedidos existentes" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        Order.create!(amount: 200.00, category: "Livros",      order_date: Date.new(2026, 1, 15))
        Order.create!(amount: 300.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 20))
      end

      it "retorna HTTP 200 (critério 1)" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
      end

      it "exibe o indicador de total de vendas correto (critério 2)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-total"')
        expect(to_number(element_text(response.body, "metric-total"))).to eq(600.0)
      end

      it "exibe o indicador de número de pedidos correto (critério 3)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-count"')
        expect(to_number(element_text(response.body, "metric-count"))).to eq(3.0)
      end

      it "exibe o indicador de ticket médio correto (critério 4)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-average"')
        expect(to_number(element_text(response.body, "metric-average"))).to eq(200.0)
      end

      it "exibe uma tabela listando os pedidos com categoria e valor (critério 5)" do
        get "/dashboard"
        expect(response.body).to include('id="orders-table"')
        doc = Nokogiri::HTML(response.body)
        table = doc.at_css("#orders-table")
        expect(table).not_to be_nil
        text = table.text
        expect(text).to include("Eletrônicos")
        expect(text).to include("Livros")
        expect(text).to include("100")
        expect(text).to include("200")
        expect(text).to include("300")
      end

      it "exibe uma representação gráfica com um elemento por categoria (critério 6)" do
        get "/dashboard"
        expect(response.body).to include('id="chart"')
        doc = Nokogiri::HTML(response.body)
        chart = doc.at_css("#chart")
        expect(chart).not_to be_nil
        bars = chart.css(".chart-bar")
        expect(bars.size).to eq(2) # Eletrônicos e Livros
      end

      it "a soma dos valores da tabela é consistente com o total (critério 10)" do
        get "/dashboard"
        doc = Nokogiri::HTML(response.body)
        table = doc.at_css("#orders-table")
        # Soma todos os números monetários presentes nas células da tabela.
        values = table.css("td").map { |td| td.text }.select { |t| t =~ /\d/ }.map { |t| to_number(t) }
        # Considera apenas valores que representam pedidos (>= 100 neste cenário).
        order_values = values.select { |v| v >= 100 }
        expect(order_values.sum).to eq(600.0)
        expect(to_number(element_text(response.body, "metric-total"))).to eq(order_values.sum)
      end
    end

    context "com filtro por intervalo de datas" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        Order.create!(amount: 200.00, category: "Livros",      order_date: Date.new(2026, 1, 15))
        Order.create!(amount: 300.00, category: "Eletrônicos", order_date: Date.new(2026, 2, 20))
      end

      it "restringe os pedidos considerados nos indicadores e na tabela (critério 7)" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        expect(response).to have_http_status(:ok)
        expect(to_number(element_text(response.body, "metric-total"))).to eq(300.0)
        expect(to_number(element_text(response.body, "metric-count"))).to eq(2.0)
        expect(to_number(element_text(response.body, "metric-average"))).to eq(150.0)

        doc = Nokogiri::HTML(response.body)
        table = doc.at_css("#orders-table")
        expect(table.text).not_to include("300")
      end

      it "reflete apenas pedidos dentro do intervalo, excluindo os de fora (critério 9)" do
        get "/dashboard", params: { start_date: "2026-02-01", end_date: "2026-02-28" }
        expect(to_number(element_text(response.body, "metric-total"))).to eq(300.0)
        expect(to_number(element_text(response.body, "metric-count"))).to eq(1.0)
        expect(to_number(element_text(response.body, "metric-average"))).to eq(300.0)
      end

      it "exibe o formulário de filtro com os campos start_date e end_date" do
        get "/dashboard"
        expect(response.body).to include('id="filter-form"')
        expect(response.body).to include('name="start_date"')
        expect(response.body).to include('name="end_date"')
      end
    end

    context "sem pedidos no período filtrado" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
      end

      it "exibe o estado vazio sem erro HTTP 500 (critério 8)" do
        get "/dashboard", params: { start_date: "2030-01-01", end_date: "2030-12-31" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="empty-state"')
      end

      it "exibe o estado vazio quando não há nenhum pedido" do
        Order.delete_all
        get "/dashboard"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="empty-state"')
      end
    end
  end
end
