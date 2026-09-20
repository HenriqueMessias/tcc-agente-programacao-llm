# Testes-oráculo de T2 — independentes do agente. Cada exemplo corresponde a
# um critério de aceitação de tasks/t2_dashboard/task.md. Usa Nokogiri para
# extrair texto por id, em vez de regex sobre a estrutura HTML (mais robusto
# a variações razoáveis de marcação entre implementações diferentes).
require_relative "../spec/rails_helper"

RSpec.describe "Dashboard (oráculo T2)", type: :request do
  before { host! "127.0.0.1" }

  def create_order!(amount:, category:, order_date:)
    Order.create!(amount: amount, category: category, order_date: order_date)
  end

  def doc
    Nokogiri::HTML(response.body)
  end

  def text_of(id)
    doc.at_css("##{id}")&.text.to_s
  end

  # Critério 1
  it "critério 1: dashboard retorna HTTP 200" do
    get dashboard_path
    expect(response).to have_http_status(:ok)
  end

  # Critérios 2, 3, 4
  it "critérios 2-4: indicadores refletem soma, contagem e média corretas" do
    create_order!(amount: 100, category: "A", order_date: Date.new(2026, 1, 5))
    create_order!(amount: 300, category: "B", order_date: Date.new(2026, 1, 10))
    get dashboard_path
    expect(text_of("metric-total")).to include("400")
    expect(text_of("metric-count")).to include("2")
    expect(text_of("metric-average")).to include("200")
  end

  # Critério 5
  it "critério 5: tabela lista os pedidos com categoria e valor" do
    create_order!(amount: 100, category: "Eletrônicos", order_date: Date.new(2026, 1, 5))
    get dashboard_path
    expect(text_of("orders-table")).to include("Eletrônicos")
    expect(text_of("orders-table")).to include("100")
  end

  # Critério 6
  it "critério 6: gráfico exibe um elemento por categoria" do
    create_order!(amount: 100, category: "A", order_date: Date.new(2026, 1, 1))
    create_order!(amount: 200, category: "B", order_date: Date.new(2026, 1, 2))
    get dashboard_path
    expect(doc.css(".chart-bar").size).to eq(2)
  end

  # Critério 7 e 9
  it "critérios 7 e 9: filtro por intervalo restringe os pedidos considerados" do
    create_order!(amount: 100, category: "A", order_date: Date.new(2026, 1, 5))
    create_order!(amount: 500, category: "B", order_date: Date.new(2026, 3, 5))
    get dashboard_path, params: { start_date: "2026-01-01", end_date: "2026-01-31" }
    expect(text_of("metric-count")).to include("1")
    expect(text_of("metric-total")).to include("100")
    expect(text_of("metric-total")).not_to include("500")
  end

  # Critério 8
  it "critério 8: filtro sem correspondência exibe estado vazio sem erro 500" do
    create_order!(amount: 100, category: "A", order_date: Date.new(2026, 1, 5))
    get dashboard_path, params: { start_date: "2030-01-01", end_date: "2030-01-02" }
    expect(response).to have_http_status(:ok)
    expect(doc.at_css("#empty-state")).not_to be_nil
  end

  # Critério 10
  it "critério 10: soma da tabela do período filtrado é consistente com o total exibido" do
    create_order!(amount: 120, category: "A", order_date: Date.new(2026, 1, 5))
    create_order!(amount: 80, category: "B", order_date: Date.new(2026, 1, 6))
    get dashboard_path, params: { start_date: "2026-01-01", end_date: "2026-01-31" }
    expect(text_of("metric-total")).to include("200")
  end
end
