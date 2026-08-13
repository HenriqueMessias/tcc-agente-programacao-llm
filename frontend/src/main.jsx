import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import "../styles.css";

const API_URL = import.meta.env.VITE_API_URL || "";
const initialContract = `{
  "name": "web-app",
  "description": "Aplicação web gerada pelo usuário",
  "elements": [{ "tag": "main", "id": "app", "classes": [] }],
  "required_ids": ["app"],
  "required_tags": ["main"],
  "required_classes": [],
  "acceptance_criteria": []
}`;

function Icon({ children }) { return <span className="nav-icon">{children}</span>; }

function App() {
  const [prompt, setPrompt] = useState("");
  const [contract, setContract] = useState(initialContract);
  const [provider, setProvider] = useState("openai");
  const [mode, setMode] = useState("restricted");
  const [loading, setLoading] = useState(false);
  const [html, setHtml] = useState("");
  const [status, setStatus] = useState("Aguardando");
  const [error, setError] = useState("");
  const [metrics, setMetrics] = useState({});
  const [diagnostics, setDiagnostics] = useState(null);
  const [activity, setActivity] = useState([{ title: "Aguardando instrução", detail: "O pipeline está pronto para começar", type: "muted" }]);
  const [specVisible, setSpecVisible] = useState(true);

  const addActivity = (title, detail, type = "done") => setActivity((items) => [...items, { title, detail, type }]);
  const reset = () => { setPrompt(""); setContract(initialContract); setHtml(""); setDiagnostics(null); setMetrics({}); setStatus("Aguardando"); setError(""); setActivity([{ title: "Aguardando instrução", detail: "O pipeline está pronto para começar", type: "muted" }]); };

  async function generate() {
    setError("");
    if (!prompt.trim()) return setError("Descreva o sistema que deseja construir.");
    let parsedContract;
    try { parsedContract = JSON.parse(contract); } catch { return setError("O contrato SDD não é um JSON válido."); }
    setLoading(true); setHtml(""); setStatus("Em execução"); setActivity([]); addActivity("Planejamento aprovado", "Paperclip validou o contrato SDD"); addActivity("Hermes está gerando", "Enviando intenção ao modelo...", "current");
    try {
      const response = await fetch(`${API_URL}/api/v1/generate`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ contract: parsedContract, prompt, provider, mode, max_retries: 3, budget_usd: 0.5 }) });
      const result = await response.json();
      if (!response.ok) throw new Error(result.detail || "A API rejeitou a solicitação.");
      setHtml(result.html || ""); setMetrics(result.telemetry || {}); setDiagnostics(result); setStatus(result.status === "SUCCESS" ? "Validado" : "Interrompido");
      setActivity((items) => [...items.filter((item) => item.type !== "current"), { title: "TDD e DOM validados", detail: result.status === "SUCCESS" ? "A estrutura atende ao contrato" : "O ciclo encontrou falhas", type: result.status === "SUCCESS" ? "done" : "current" }, ...(result.status === "SUCCESS" ? [{ title: "Projeto pronto", detail: "Preview renderizado com sucesso", type: "done" }] : [])]);
    } catch (requestError) { setError(requestError.message || "Não foi possível conectar à API."); setStatus("Falha"); addActivity("Execução interrompida", requestError.message || "Falha de conexão", "current"); } finally { setLoading(false); }
  }

  const statusClass = status === "Validado" ? "success" : status === "Interrompido" || status === "Falha" ? "failed" : "";
  return <>
    <style>{`.runtime-select{display:flex;align-items:center;gap:4px;color:#777182;font-size:9px}.runtime-select select{padding:5px 6px;border:1px solid #ffffff12;border-radius:6px;color:#aaa4b6;background:#ffffff05;font-size:10px;outline:0}.runtime-select select:focus{border-color:#7762b9}@media(max-width:750px){.runtime-select{font-size:0}.runtime-select select{max-width:78px}}`}</style>
    <div className="ambient ambient-one" /><div className="ambient ambient-two" />
    <div className="app-frame">
      <aside className="sidebar">
        <div className="brand"><span className="brand-orbit"><span>H</span></span><span>hermes<small>studio</small></span></div>
        <button className="new-project" onClick={reset}><span className="plus">+</span> Novo projeto</button>
        <nav className="main-nav"><a className="active" href="#builder"><Icon>✦</Icon> Builder</a><a href="#activity"><Icon>◌</Icon> Atividade <b className="nav-count">3</b></a><a href="#specification"><Icon>◇</Icon> Especificação</a></nav>
        <div className="sidebar-label">PROJETO ATUAL</div><div className="project-card"><span className="project-dot" /><div><strong>web-app</strong><small>Última edição agora</small></div><button>•••</button></div>
        <div className="sidebar-bottom"><div className="system-status"><span /><div><strong>{loading ? "Ciclo em execução" : "Sistemas online"}</strong><small>Pipeline Hermes conectado</small></div></div><div className="profile"><span className="avatar">DV</span><div><strong>Desenvolvedor</strong><small>Workspace local</small></div><button>⌄</button></div></div>
      </aside>
      <main className="main-content" id="builder">
        <header className="topbar"><div className="breadcrumbs"><span>Projetos</span><b>/</b><strong>web-app</strong></div><div className="top-actions"><span className="secure-label"><i /> Sandbox seguro</span><button className="icon-button">♢</button><button className="share-button" onClick={() => navigator.clipboard?.writeText(window.location.href)}>Compartilhar <span>↗</span></button></div></header>
        <div className="content-grid">
          <section className="builder-column"><div className="hero-copy"><div className="status-line"><span className="sparkle">✦</span> CICLO COGNITIVO RESTRITIVO <span className="line" /><span className="version">v0.1 experimental</span></div><h1>O que vamos <span>construir</span> hoje?</h1><p>Descreva sua ideia. O Hermes transforma intenção em uma interface funcional, testada e pronta para evoluir.</p></div>
            <section className="prompt-card"><div className="prompt-top"><span className="prompt-label"><span className="pulse" /> Hermes está pronto</span><span className="shortcut">⌘ ↵</span></div><textarea value={prompt} onChange={(event) => setPrompt(event.target.value)} onKeyDown={(event) => { if ((event.metaKey || event.ctrlKey) && event.key === "Enter") generate(); }} rows="5" placeholder="Crie um dashboard de vendas moderno com métricas, tabela de pedidos, navegação lateral e tema escuro..." /><div className="prompt-footer"><div className="prompt-tools"><button className="tool-button" onClick={() => setError("O anexo de arquivos será conectado ao sandbox na próxima etapa.")}>＋ <span>Adicionar contexto</span></button><button className="tool-button" onClick={() => setPrompt("Crie uma landing page SaaS premium com hero, benefícios, depoimentos e um call to action destacado.")}>▦ <span>Usar exemplo</span></button><label className="runtime-select">Modelo<select value={provider} onChange={(event) => setProvider(event.target.value)}><option value="openai">OpenAI</option><option value="anthropic">Anthropic</option><option value="groq">Groq</option></select></label><label className="runtime-select">Execução<select value={mode} onChange={(event) => setMode(event.target.value)}><option value="restricted">Restricted</option><option value="baseline">Baseline</option></select></label></div><button className="generate-button" onClick={generate} disabled={loading}><span>{loading ? "Executando ciclo..." : "Gerar sistema"}</span><b>{loading ? "◌" : "✦"}</b></button></div></section>
            <div className="quick-prompts"><span>Comece com uma ideia:</span>{["Landing page SaaS","Dashboard financeiro","Tela de login"].map((label) => <button key={label} onClick={() => setPrompt(label === "Landing page SaaS" ? "Crie uma landing page SaaS com hero, benefícios, depoimentos e call to action." : label === "Dashboard financeiro" ? "Crie um dashboard financeiro com cards de saldo, gráfico de receitas e transações recentes." : "Crie uma página de login minimalista com autenticação e recuperação de senha.")}>{label}</button>)}</div>
            <div className="workspace-section" id="specification"><div className="section-heading"><div><span className="section-kicker">CONTRATO EXECUTÁVEL</span><h2>Especificação SDD</h2></div><button className="collapse-button" onClick={() => setSpecVisible(!specVisible)}>{specVisible ? "Ocultar" : "Exibir"} <span>{specVisible ? "⌃" : "⌄"}</span></button></div>{specVisible && <div className="spec-body"><p>Defina os elementos que o navegador deverá encontrar. O agente pode criar livremente dentro destes limites.</p><textarea value={contract} onChange={(event) => setContract(event.target.value)} className="code-editor" rows="12" /><div className="spec-footer"><span><i className="valid-icon">✓</i> JSON validável</span><span>Paperclip governance ativo</span></div></div>}</div>
          </section>
          <aside className="inspector" id="activity"><div className="inspector-head"><div><span className="section-kicker">LIVE WORKSPACE</span><h2>Visão geral</h2></div><span className={`status-badge ${statusClass}`}>{status}</span></div><div className="preview-shell"><div className="preview-toolbar"><div className="window-dots"><i /><i /><i /></div><span>preview.hermes.local</span><button onClick={() => setHtml((current) => current)}>↻</button></div>{loading && <div className="preview-loading"><div className="loading-ring" /><strong>Construindo sua interface</strong><span>O Hermes está gerando e validando...</span></div>}{html ? <iframe title="Preview da aplicação gerada" srcDoc={html} sandbox="allow-scripts" /> : <div className="preview-empty"><span>✦</span><strong>Seu preview aparecerá aqui</strong><small>Descreva uma ideia e inicie o ciclo</small></div>}</div><div className="metrics-grid"><Metric label="Tokens economizados" value={metrics.saved_tokens} suffix="nesta execução" /><Metric label="Compressão" value={metrics.compression_ratio ? `${((1 - metrics.compression_ratio) * 100).toFixed(1)}%` : "—"} suffix="contexto otimizado" /><Metric label="Ciclos" value={metrics.cycle_number ?? "—"} suffix="até validação" /><Metric label="Custo estimado" value={metrics.cost_usd ? `$${Number(metrics.cost_usd).toFixed(4)}` : "—"} suffix="limite $0.50" /></div><div className="activity-box"><div className="activity-title"><strong>Atividade do agente</strong><button onClick={() => setActivity([])}>Limpar</button></div><div className="timeline">{activity.map((item, index) => <div className={`timeline-item ${item.type}`} key={`${item.title}-${index}`}><span className="timeline-icon">{item.type === "done" ? "✓" : item.type === "current" ? "◌" : "○"}</span><div><strong>{item.title}</strong><small>{item.detail}</small></div></div>)}</div></div>{diagnostics && <div className="diagnostics"><div className="diagnostic-title"><strong>Diagnóstico técnico</strong><code>{diagnostics.approval_id || "—"}</code></div><pre>{JSON.stringify({ status: diagnostics.status, mode: diagnostics.mode, errors: diagnostics.errors || [], telemetry: diagnostics.telemetry }, null, 2)}</pre></div>}</aside>
        </div>
      </main>
    </div>{error && <button className="toast-error" onClick={() => setError("")}>{error}</button>}
  </>;
}

function Metric({ label, value, suffix }) { return <div className="metric"><span>{label}</span><strong>{value === undefined ? "—" : Number.isFinite(Number(value)) && typeof value !== "string" ? Number(value).toLocaleString("pt-BR") : value}</strong><small>{suffix}</small></div>; }

createRoot(document.getElementById("root")).render(<App />);
