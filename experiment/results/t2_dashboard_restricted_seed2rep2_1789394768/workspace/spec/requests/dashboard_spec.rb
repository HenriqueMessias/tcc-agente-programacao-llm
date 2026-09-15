require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  # Helper: extrai o conteúdo textual de um elemento por id.
  def element_text(html, id)
    doc = Nokogiri::HTML(html)
    node = doc.at_css("##{id}")
    node ? node.text.strip : nil
  end

  def parse_money(text)
    return nil if text.nil?
    # Remove tudo que não for dígito, separador decimal, sinal ou vírgula.
    cleaned = text.gsub(/[^\d,.\-]/, "")
    # Normaliza formato pt-BR (1.234,56) para (1234.56) quando aplicável.
    if cleaned.include?(",") && cleaned.include?(".")
      cleaned = cleaned.gsub(".", "").gsub(",", ".")
    elsif cleaned.include?(",")
      cleaned = cleaned.gsub(",", ".")
    end
    cleaned.to_f
  end

  describe "GET /dashboard" do
    context "com pedidos existentes" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        Order.create!(amount: 200.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 15))
        Order.create!(amount: 300.00, category: "Roupas",      order_date: Date.new(2026, 1, 20))
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
        expect(parse_money(element_text(response.body, "metric-total"))).to eq(600.0)
      end

      it "exibe o número de pedidos correto (critério 3)" do
        get "/dashboard"
        expect(element_text(response.body, "metric-count")).to include("3")
      end

      it "exibe o ticket médio correto (critério 4)" do
        get "/dashboard"
        expect(parse_money(element_text(response.body, "metric-average"))).to eq(200.0)
      end

      it "exibe a tabela de pedidos com categoria e valor (critério 5)" do
        get "/dashboard"
        doc = Nokogiri::HTML(response.body)
        table = doc.at_css("#orders-table")
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
        doc = Nokogiri::HTML(response.body)
        chart = doc.at_css("#chart")
        expect(chart).not_to be_nil
        bars = chart.css(".chart-bar")
        expect(bars.size).to eq(2) # Eletrônicos e Roupas
      end

      it "a soma dos valores da tabela é consistente com o total (critério 10)" do
        get "/dashboard"
        doc = Nokogiri::HTML(response.body)
        table = doc.at_css("#orders-table")
        expect(table).not_to be_nil
        # Soma todos os números monetários encontrados nas células da tabela.
        values = table.css("td").map { |td| parse_money(td.text) }.compact
        # Considera apenas valores > 0 (evita datas/ids zerados).
        sum = values.select { |v| v > 0 }.sum
        expect(sum).to be >= 600.0
        expect(parse_money(element_text(response.body, "metric-total"))).to eq(600.0)
      end
    end

    context "com filtro por intervalo de datas" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
        Order.create!(amount: 200.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 15))
        Order.create!(amount: 300.00, category: "Roupas",      order_date: Date.new(2026, 2, 20))
      end

      it "restringe os pedidos considerados (critério 7)" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        expect(response).to have_http_status(:ok)
        expect(parse_money(element_text(response.body, "metric-total"))).to eq(300.0)
        expect(element_text(response.body, "metric-count")).to include("2")
      end

      it "exclui pedidos fora do intervalo (critério 9)" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        doc = Nokogiri::HTML(response.body)
        table = doc.at_css("#orders-table")
        expect(table.text).not_to include("300")
        expect(parse_money(element_text(response.body, "metric-total"))).to eq(300.0)
      end

      it "exibe o formulário de filtro com os campos corretos" do
        get "/dashboard"
        doc = Nokogiri::HTML(response.body)
        form = doc.at_css("#filter-form")
        expect(form).not_to be_nil
        expect(form.at_css('[name="start_date"]')).not_to be_nil
        expect(form.at_css('[name="end_date"]')).not_to be_nil
      end
    end

    context "com intervalo sem pedidos" do
      before do
        Order.create!(amount: 100.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 10))
      end

      it "exibe o estado vazio sem erro 500 (critério 8)" do
        get "/dashboard", params: { start_date: "2030-01-01", end_date: "2030-12-31" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="empty-state"')
      end

      it "mostra métricas zeradas no estado vazio" do
        get "/dashboard", params: { start_date: "2030-01-01", end_date: "2030-12-31" }
        expect(parse_money(element_text(response.body, "metric-total"))).to eq(0.0)
        expect(element_text(response.body, "metric-count")).to include("0")
      end
    end

    context "sem nenhum pedido no banco" do
      it "retorna 200 e exibe estado vazio" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="empty-state"')
      end
    end
  end
end
