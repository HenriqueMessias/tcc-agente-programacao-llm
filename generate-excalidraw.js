#!/usr/bin/env node
// Generate Excalidraw mind map — 2-band layout, no overlaps
const fs = require("fs");
const path = require("path");

let idx = 0;
const ts = Date.now();

function el(params) {
  const base = {
    angle: 0, strokeStyle: "solid", groupIds: [], frameId: null,
    index: "a" + idx++,
    seed: Math.floor(Math.random() * 2000000000),
    version: 1, versionNonce: Math.floor(Math.random() * 2000000000),
    isDeleted: false, updated: ts, link: null, locked: false,
  };
  if (params.type === "text") {
    return { ...base, ...params, roundness: params.roundness || null,
      boundElements: null, containerId: null, originalText: params.text,
      autoResize: true, lineHeight: 1.25 };
  }
  if (params.type === "arrow") {
    return { ...base, ...params, roundness: params.roundness || { type: 2 },
      boundElements: null, elbowed: false,
      startBinding: params.startBinding || null,
      endBinding: params.endBinding || null,
      startArrowhead: params.startArrowhead || null,
      endArrowhead: params.endArrowhead || "arrow" };
  }
  return { ...base, ...params, roundness: params.roundness || { type: 3 },
    boundElements: params.boundElements || null };
}

function bindings(ids) {
  if (!ids || ids.length === 0) return null;
  return ids.map((id) => ({ id, type: "arrow" }));
}

const E = [];

// ═══════════════════════════════════════
// ROOT — centered top
// ═══════════════════════════════════════
E.push(el({ id:"root-bg", type:"rectangle", x:550, y:30, width:620, height:80,
  strokeColor:"#1e3a5f", backgroundColor:"#1a365d", fillStyle:"solid",
  strokeWidth:2, roughness:0, opacity:100,
  boundElements: bindings(["arr-r-1","arr-r-2","arr-r-3","arr-r-4","arr-r-5","arr-r-6","arr-r-7","arr-r-8"]) }));
E.push(el({ id:"root-text", type:"text", x:565, y:38, width:590, height:64,
  text:"AGENTE DE APOIO À PROGRAMAÇÃO COM LLM\nMetaprompting Arquitetural Restritivo (SDD + TDD + Guardrails)",
  fontSize:16, fontFamily:2, textAlign:"center", verticalAlign:"middle",
  strokeColor:"#ffffff", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ═══════════════════════════════════════
// BAND 1 — Branches 1-4  (y=180 headers, y=380 content)
// ═══════════════════════════════════════
const band1 = [
  { id:"b1", xh:50,  w:440, label:"1. PROBLEMÁTICA CENTRAL",              stroke:"#9b2c2c", bg:"#c53030", contentY:380 },
  { id:"b2", xh:520, w:380, label:"2. FUNDAMENTAÇÃO TEÓRICA",              stroke:"#553c9a", bg:"#805ad5", contentY:380 },
  { id:"b3", xh:930, w:380, label:"3. HIPÓTESE + CONGRUÊNCIA",             stroke:"#9c4221", bg:"#dd6b20", contentY:380 },
  { id:"b4", xh:1340,w:680, label:"4. ARQUITETURA DO PROTÓTIPO",           stroke:"#1e4e8c", bg:"#2b6cb0", contentY:380 },
];

for (const b of band1) {
  const cx = b.xh + b.w/2;
  const arrId = "arr-r-" + b.id.charAt(1);
  const subArrId = "arr-" + b.id + "-sub";
  // header
  E.push(el({ id:b.id+"-bg", type:"rectangle", x:b.xh, y:180, width:b.w, height:46,
    strokeColor:b.stroke, backgroundColor:b.bg, fillStyle:"solid",
    strokeWidth:1.5, roughness:0, opacity:100, boundElements: bindings([arrId, subArrId]) }));
  E.push(el({ id:b.id+"-text", type:"text", x:b.xh+10, y:190, width:b.w-20, height:26,
    text:b.label, fontSize:16, fontFamily:2, textAlign:"center", verticalAlign:"middle",
    strokeColor:"#ffffff", backgroundColor:"transparent", fillStyle:"solid",
    strokeWidth:0, roughness:0, opacity:100 }));
  // sub-arrow
  E.push(el({ id:subArrId, type:"arrow", x:cx-5, y:226, width:10, height:154,
    points:[[0,0],[0,154]], strokeColor:b.stroke, strokeWidth:1.2, roughness:0, opacity:100 }));
}

// ═══════════════════════════════════════
// BAND 2 — Branches 5-8  (y=960 headers, y=1160 content)
// ═══════════════════════════════════════
const band2 = [
  { id:"b5", xh:50,  w:460, label:"5. VARIÁVEIS DO EXPERIMENTO",           stroke:"#1c6b6b", bg:"#2c7a7b", contentY:1160 },
  { id:"b6", xh:540, w:360, label:"6. MÉTODO",                             stroke:"#1c6838", bg:"#2f855a", contentY:1160 },
  { id:"b7", xh:930, w:440, label:"7. RESULTADOS ESPERADOS",               stroke:"#1b6b3a", bg:"#38a169", contentY:1160 },  // green success theme
  { id:"b8", xh:1400,w:620, label:"8. CONTRIBUIÇÃO ESPERADA",              stroke:"#6b5a2f", bg:"#8b7a4f", contentY:1160 },
];

for (const b of band2) {
  const cx = b.xh + b.w/2;
  const arrId = "arr-r-" + b.id.charAt(1);
  const subArrId = "arr-" + b.id + "-sub";
  E.push(el({ id:b.id+"-bg", type:"rectangle", x:b.xh, y:960, width:b.w, height:46,
    strokeColor:b.stroke, backgroundColor:b.bg, fillStyle:"solid",
    strokeWidth:1.5, roughness:0, opacity:100, boundElements: bindings([arrId, subArrId]) }));
  E.push(el({ id:b.id+"-text", type:"text", x:b.xh+10, y:970, width:b.w-20, height:26,
    text:b.label, fontSize:16, fontFamily:2, textAlign:"center", verticalAlign:"middle",
    strokeColor:"#ffffff", backgroundColor:"transparent", fillStyle:"solid",
    strokeWidth:0, roughness:0, opacity:100 }));
  E.push(el({ id:subArrId, type:"arrow", x:cx-5, y:1006, width:10, height:154,
    points:[[0,0],[0,154]], strokeColor:b.stroke, strokeWidth:1.2, roughness:0, opacity:100 }));
}

// ═══════════════════════════════════════
// ARROWS: Root (y=115) → Headers
// ═══════════════════════════════════════
// Root bottom edge: x=550..1170, y=110
// Band 1 headers at y=180 (dy=70)
const rootArrows = [
  // To Band 1
  { id:"arr-r-1", bx:620, by:110, px:-350, py:70, band:1 },
  { id:"arr-r-2", bx:750, by:110, px:-40,  py:70, band:1 },
  { id:"arr-r-3", bx:1050,by:110, px:70,   py:70, band:1 },
  { id:"arr-r-4", bx:1170,by:110, px:510,  py:70, band:1 },
  // To Band 2 (longer, dy=850 to y=960)
  { id:"arr-r-5", bx:600, by:110, px:-320, py:850, band:2 },
  { id:"arr-r-6", bx:750, by:110, px:-30,  py:850, band:2 },
  { id:"arr-r-7", bx:1050,by:110, px:100,  py:850, band:2 },
  { id:"arr-r-8", bx:1160,by:110, px:550,  py:850, band:2 },
];
for (const a of rootArrows) {
  E.push(el({ id:a.id, type:"arrow", x:a.bx, y:a.by,
    width:Math.abs(a.px)+10, height:a.py+10,
    points:[[0,0],[a.px,a.py]],
    strokeColor:"#a0aec0", strokeWidth:1.5, roughness:0, opacity:100 }));
}

// ═══════════════════════════════════════════════
// CONTENT BOXES — BAND 1 (y=380, h depends)
// ═══════════════════════════════════════════════

// ── B1: PROBLEMÁTICA (x:50, w:440, needs ~470px height) ──
const b1x = 50, b1w = 440, b1y = 380;
E.push(el({ id:"eq-box", type:"rectangle", x:b1x, y:b1y, width:b1w, height:175,
  strokeColor:"#e53e3e", backgroundColor:"#fff5f5", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"eq-title", type:"text", x:b1x+15, y:b1y+8, width:b1w-30, height:22,
  text:"PERGUNTA DE PESQUISA", fontSize:13, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#c53030", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"eq-text", type:"text", x:b1x+15, y:b1y+34, width:b1w-30, height:130,
  text:"Em que medida a imposição de um ciclo cognitivo restritivo — integrando SDD, TDD e\nGuardrails como mecanismos de metaprompting arquitetural — reduz a taxa de alucinação\ne as regressões de código, ao mesmo tempo em que aumenta a eficiência no consumo de\ntokens, em agentes LLM aplicados a tarefas de geração, explicação e correção de código,\nquando comparado ao fluxo gerativo livre?",
  fontSize:11, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Causa-raiz
const b1y2 = b1y + 195;
E.push(el({ id:"causa-box", type:"rectangle", x:b1x, y:b1y2, width:b1w, height:55,
  strokeColor:"#e53e3e", backgroundColor:"#fed7d7", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"causa-text", type:"text", x:b1x+15, y:b1y2+8, width:b1w-30, height:40,
  text:"CAUSA-RAIZ: Ausência de governança estrutural —\no agente age, mas não planeja nem valida antes de entregar",
  fontSize:11, fontFamily:2, textAlign:"center", verticalAlign:"middle",
  strokeColor:"#9b2c2c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Dores
const b1y3 = b1y2 + 75;
E.push(el({ id:"dores-box", type:"rectangle", x:b1x, y:b1y3, width:b1w, height:125,
  strokeColor:"#e53e3e", backgroundColor:"#fff5f5", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"dores-title", type:"text", x:b1x+15, y:b1y3+8, width:b1w-30, height:20,
  text:"DORES OBSERVADAS (fluxo livre)", fontSize:12, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#c53030", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"dor1", type:"text", x:b1x+15, y:b1y3+32, width:b1w-30, height:28,
  text:"🔴 ALUCINAÇÃO: Funções/bibliotecas inexistentes, lógica fora do requisito",
  fontSize:10, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"dor2", type:"text", x:b1x+15, y:b1y3+60, width:b1w-30, height:28,
  text:"🟠 REGRESSÃO: Quebra de código já testado em outras partes do sistema",
  fontSize:10, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"dor3", type:"text", x:b1x+15, y:b1y3+88, width:b1w-30, height:28,
  text:"🟡 DESPERDÍCIO: 500 linhas onde 100 bastam, features extras não solicitadas",
  fontSize:10, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ── B2: FUNDAMENTAÇÃO (x:520, w:380) ──
const b2x = 520, b2w = 380, b2y = 380;
E.push(el({ id:"fund-box", type:"rectangle", x:b2x, y:b2y, width:b2w, height:460,
  strokeColor:"#805ad5", backgroundColor:"#faf5ff", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"fund-title", type:"text", x:b2x+15, y:b2y+8, width:b2w-30, height:22,
  text:"DIAGNÓSTICO DE KARPATHY (2025)", fontSize:13, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#805ad5", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
const fp = [
  "1. Think Before Coding → Forçar planejamento antes da execução",
  "2. Simplicity First → Não adicionar nada além do solicitado",
  "3. Surgical Changes → Modificações isoladas, sem efeitos colaterais",
  "4. Goal-Driven Execution → Ciclo de auto-revisão até excelência",
];
fp.forEach((t, i) => {
  E.push(el({ id:"fund-p"+(i+1), type:"text", x:b2x+20, y:b2y+40+i*42, width:b2w-40, height:38,
    text:t, fontSize:11, fontFamily:2, textAlign:"left", verticalAlign:"top",
    strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
    strokeWidth:0, roughness:0, opacity:100 }));
});
E.push(el({ id:"fund-lacuna-box", type:"rectangle", x:b2x+25, y:b2y+218, width:b2w-50, height:55,
  strokeColor:"#805ad5", backgroundColor:"#e9d8fd", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"fund-lacuna-text", type:"text", x:b2x+35, y:b2y+224, width:b2w-70, height:43,
  text:"LACUNA: System prompts sozinhos não bastam —\né preciso ENFORCEMENT programático em runtime",
  fontSize:10, fontFamily:2, textAlign:"center", verticalAlign:"middle",
  strokeColor:"#553c9a", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"fund-refs", type:"text", x:b2x+20, y:b2y+290, width:b2w-40, height:155,
  text:"REFERÊNCIAS\n\n• Karpathy, A. — Análise do comportamento\nde agentes de IA autônomos (2025)\n\n• Repositório CLAUDE.md — GitHub,\n+130.000 ★ — estratégia de diretrizes\ncentralizadas para agentes\n\n• Nous Research — Hermes Agent\nFramework com memória persistente\n\n• Paperclip — sistema de governança\npara orquestração de agentes",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#718096", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ── B3: HIPÓTESE + CONGRUÊNCIA (x:930, w:380) ──
const b3x = 930, b3w = 380, b3y = 380;
// Hipótese
E.push(el({ id:"hip-box", type:"rectangle", x:b3x, y:b3y, width:b3w, height:140,
  strokeColor:"#dd6b20", backgroundColor:"#fffaf0", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"hip-title", type:"text", x:b3x+15, y:b3y+8, width:b3w-30, height:22,
  text:"HIPÓTESE (H₁)", fontSize:13, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#dd6b20", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"hip-text", type:"text", x:b3x+15, y:b3y+32, width:b3w-30, height:98,
  text:"Um loop cognitivo restritivo — que intercala SDD\n(especificação contratual), TDD (validação contínua\ncontra um Test Harness) e Guardrails (bloqueio de\nações fora de escopo) — produz código mais correto,\nconsome menos tokens e causa menos regressões\ndo que o fluxo gerativo livre.",
  fontSize:10, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Congruência
const b3y2 = b3y + 160;
E.push(el({ id:"cong-box", type:"rectangle", x:b3x, y:b3y2, width:b3w, height:300,
  strokeColor:"#dd6b20", backgroundColor:"#fffaf0", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"cong-title", type:"text", x:b3x+15, y:b3y2+8, width:b3w-30, height:22,
  text:"CONGRUÊNCIA PILAR → MECANISMO", fontSize:12, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#dd6b20", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
const congItems = [
  ["Think Before Coding  →  SDD\nSimplicity First      →  Contrato de escopo vinculante", "→ Impede features não solicitadas\ne força planejamento prévio"],
  ["Goal-Driven Execution  →  TDD + Test Harness\n                           Loop RED → GREEN → REFACTOR", "→ Agente testa, falha, corrige\ne reitera até passar"],
  ["Surgical Changes  →  Guardrails + Sandbox\n                       Isolamento de ecossistema", "→ Bloqueio de ações fora de\nescopo na camada de routing"],
];
congItems.forEach((c, i) => {
  const yy = b3y2 + 36 + i*80;
  E.push(el({ id:"cong-"+(i+1), type:"text", x:b3x+15, y:yy, width:b3w-30, height:40,
    text:c[0], fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
    strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
    strokeWidth:0, roughness:0, opacity:100 }));
  E.push(el({ id:"cong-eff-"+(i+1), type:"text", x:b3x+15, y:yy+42, width:b3w-30, height:28,
    text:c[1], fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
    strokeColor:"#9c4221", backgroundColor:"transparent", fillStyle:"solid",
    strokeWidth:0, roughness:0, opacity:100 }));
});
E.push(el({ id:"cong-note", type:"text", x:b3x+15, y:b3y2+280, width:b3w-30, height:30,
  text:"Não é metáfora — é tradução direta em engenharia.",
  fontSize:10, fontFamily:2, textAlign:"center", verticalAlign:"top",
  strokeColor:"#9c4221", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ── B4: ARQUITETURA (x:1340, w:680) ──
const b4x = 1340, b4y = 380;
const ppw = 315, hew = 315, gap = 20;
E.push(el({ id:"arq-box", type:"rectangle", x:b4x, y:b4y, width:680, height:460,
  strokeColor:"#2b6cb0", backgroundColor:"#ebf8ff", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"arq-title", type:"text", x:b4x+15, y:b4y+8, width:650, height:22,
  text:"ARQUITETURA DO PROTÓTIPO — DUAS CAMADAS", fontSize:13, fontFamily:2,
  textAlign:"center", verticalAlign:"top", strokeColor:"#2b6cb0",
  backgroundColor:"transparent", fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));

// Paperclip column
const ppX = b4x + 15;
E.push(el({ id:"arq-pp-bg", type:"rectangle", x:ppX, y:b4y+40, width:ppw, height:290,
  strokeColor:"#2c5282", backgroundColor:"#bee3f8", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"arq-pp-title", type:"text", x:ppX+10, y:b4y+48, width:ppw-20, height:22,
  text:"🧠 PAPERCLIP — Governança", fontSize:12, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#2c5282", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
const ppItems = [
  ["📋 SDD", "Gera contrato de especificação técnica antes\nde qualquer código. Usuário aprova."],
  ["🛡️ GUARDRAILS", "Bloqueia ações fora de escopo na camada\nde routing antes de consumir processamento."],
  ["💰 BUDGET CONTROL", "Define teto de tokens por tarefa.\nRastreia cada ação (auditabilidade)."],
  ["✅ APROVAÇÕES", "Orquestra tickets estruturados.\nGate humano + gate automático."],
];
ppItems.forEach((p, i) => {
  const yy = b4y + 82 + i*62;
  E.push(el({ id:"arq-pp-"+(i+1), type:"text", x:ppX+10, y:yy, width:ppw-20, height:55,
    text:p[0]+"\n"+p[1], fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
    strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
    strokeWidth:0, roughness:0, opacity:100 }));
});

// Hermes column
const heX = ppX + ppw + gap;
E.push(el({ id:"arq-he-bg", type:"rectangle", x:heX, y:b4y+40, width:hew, height:290,
  strokeColor:"#276749", backgroundColor:"#c6f6d5", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"arq-he-title", type:"text", x:heX+10, y:b4y+48, width:hew-20, height:22,
  text:"⚡ HERMES — Execução", fontSize:12, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#276749", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
const heItems = [
  ["🔄 LOOP TDD", "RED → gera testes → GREEN → implementa\n→ REFACTOR → valida contra o Harness"],
  ["🧪 TEST HARNESS", "Suíte de testes como critério objetivo\nde sucesso. Falhou? → lê erro → reescreve."],
  ["📦 SANDBOXING", "Execução isolada (Docker/Modal).\nSkills persistentes entre sessões."],
  ["🔁 AUTO-CORREÇÃO", "Loop autônomo: implementa → testa → falha\n→ analisa log → corrige → repete até passar."],
];
heItems.forEach((h, i) => {
  const yy = b4y + 82 + i*62;
  E.push(el({ id:"arq-he-"+(i+1), type:"text", x:heX+10, y:yy, width:hew-20, height:55,
    text:h[0]+"\n"+h[1], fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
    strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
    strokeWidth:0, roughness:0, opacity:100 }));
});

// Fluxo
const fluxY = b4y + 345;
E.push(el({ id:"arq-fluxo-box", type:"rectangle", x:b4x+10, y:fluxY, width:660, height:100,
  strokeColor:"#2b6cb0", backgroundColor:"#ebf8ff", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"arq-fluxo-title", type:"text", x:b4x+20, y:fluxY+6, width:640, height:18,
  text:"FLUXO: [1] Usuário submete intenção → [2] Paperclip gera spec + usuário aprova + define budget → [3] Hermes executa loop TDD → [4] Paperclip audita e reporta",
  fontSize:9, fontFamily:2, textAlign:"center", verticalAlign:"top",
  strokeColor:"#2b6cb0", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"arq-fluxo-detail", type:"text", x:b4x+20, y:fluxY+28, width:640, height:65,
  text:"Se PASSOU nos testes → REFACTOR → registra skill → entrega ao usuário\nSe FALHOU → Hermes lê o log de erro → reescreve → submete novamente (loop até N tentativas ou teto de tokens)\nPaperclip garante: orçamento respeitado ✓ | alterações dentro do escopo ✓ | todos os testes verdes ✓",
  fontSize:8.5, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#4a5568", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ═══════════════════════════════════════════════
// CONTENT BOXES — BAND 2 (y=1160)
// ═══════════════════════════════════════════════

// ── B5: VARIÁVEIS (x:50, w:460, y:1160) ──
const b5x = 50, b5w = 460, b5y = 1160;
E.push(el({ id:"var-box", type:"rectangle", x:b5x, y:b5y, width:b5w, height:460,
  strokeColor:"#2c7a7b", backgroundColor:"#f0ffff", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"var-title", type:"text", x:b5x+15, y:b5y+8, width:b5w-30, height:22,
  text:"DESENHO EXPERIMENTAL", fontSize:13, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#2c7a7b", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));

// VI box
E.push(el({ id:"var-vi-box", type:"rectangle", x:b5x+15, y:b5y+36, width:b5w-30, height:70,
  strokeColor:"#2c7a7b", backgroundColor:"#e6fffa", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"var-vi-title", type:"text", x:b5x+25, y:b5y+40, width:b5w-50, height:16,
  text:"VARIÁVEL INDEPENDENTE: MODO DE OPERAÇÃO DO AGENTE", fontSize:10, fontFamily:2,
  textAlign:"center", verticalAlign:"top", strokeColor:"#234e52",
  backgroundColor:"transparent", fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"var-vi-text", type:"text", x:b5x+25, y:b5y+58, width:b5w-50, height:42,
  text:"Controle: Fluxo livre (prompt → resposta direta, sem restrições)\nExperimental: Arquitetura restritiva (SDD + TDD + Guardrails + Harness)",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// VD box
const vdY = b5y + 120;
E.push(el({ id:"var-vd-box", type:"rectangle", x:b5x+15, y:vdY, width:b5w-30, height:210,
  strokeColor:"#2c7a7b", backgroundColor:"#e6fffa", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"var-vd-title", type:"text", x:b5x+25, y:vdY+6, width:b5w-50, height:16,
  text:"VARIÁVEIS DEPENDENTES (o que medimos)", fontSize:10, fontFamily:2,
  textAlign:"center", verticalAlign:"top", strokeColor:"#234e52",
  backgroundColor:"transparent", fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
const vds = [
  ["VD1: Taxa de ALUCINAÇÃO", "% de blocos de código com funções, APIs ou imports inexistentes ou incorretos (varredura estática + falha no Harness)"],
  ["VD2: Taxa de REGRESSÃO", "% de tarefas concluídas onde testes preexistentes da suíte quebram após a alteração do agente"],
  ["VD3: EFICIÊNCIA DE TOKENS", "Total de tokens consumidos / tarefa concluída com sucesso (menos tokens = maior eficiência)"],
  ["VD4: Taxa de ACERTO NA 1ª ITERAÇÃO", "% de tarefas que passam no Test Harness sem necessidade do loop de auto-correção"],
];
vds.forEach((v, i) => {
  const yy = vdY + 26 + i*44;
  E.push(el({ id:"var-vd"+(i+1), type:"text", x:b5x+25, y:yy, width:b5w-50, height:40,
    text:v[0]+"\n→ "+v[1], fontSize:8.5, fontFamily:2, textAlign:"left",
    verticalAlign:"top", strokeColor:"#1a202c", backgroundColor:"transparent",
    fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
});

// Controle box
const ctrlY = vdY + 222;
E.push(el({ id:"var-controle-box", type:"rectangle", x:b5x+15, y:ctrlY, width:b5w-30, height:90,
  strokeColor:"#2c7a7b", backgroundColor:"#e6fffa", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"var-controle-title", type:"text", x:b5x+25, y:ctrlY+6, width:b5w-50, height:16,
  text:"VARIÁVEIS DE CONTROLE", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#234e52", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"var-controle-text", type:"text", x:b5x+25, y:ctrlY+26, width:b5w-50, height:58,
  text:"• Modelo LLM base fixo (ex.: Claude Opus 4 ou GPT-4o)\n• Conjunto de tarefas padronizado (20-30 issues reais open-source)\n• Temperatura e parâmetros de inferência constantes em ambas as condições\n• Cada tarefa possui suíte de testes preexistente (baseline de correção)",
  fontSize:8.5, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ── B6: MÉTODO (x:540, w:360, y:1160) ──
const b6x = 540, b6w = 360, b6y = 1160;
E.push(el({ id:"met-box", type:"rectangle", x:b6x, y:b6y, width:b6w, height:460,
  strokeColor:"#2f855a", backgroundColor:"#f0fff4", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"met-title", type:"text", x:b6x+10, y:b6y+8, width:b6w-20, height:22,
  text:"MÉTODO", fontSize:13, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#2f855a", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));

// Benchmark
const metY1 = b6y + 40;
E.push(el({ id:"met-bench-box", type:"rectangle", x:b6x+15, y:metY1, width:b6w-30, height:115,
  strokeColor:"#2f855a", backgroundColor:"#c6f6d5", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"met-bench-title", type:"text", x:b6x+25, y:metY1+6, width:b6w-50, height:16,
  text:"📦 BENCHMARK DE TAREFAS", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#22543d", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"met-bench-text", type:"text", x:b6x+25, y:metY1+24, width:b6w-50, height:85,
  text:"20-30 issues reais de\nrepositórios open-source\n\n• Correção de bugs\n• Adição de features\n• Refatoração de código\n\nCada tarefa possui suíte de\ntestes preexistente (baseline)",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Procedimento
const metY2 = metY1 + 130;
E.push(el({ id:"met-proc-box", type:"rectangle", x:b6x+15, y:metY2, width:b6w-30, height:155,
  strokeColor:"#2f855a", backgroundColor:"#c6f6d5", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"met-proc-title", type:"text", x:b6x+25, y:metY2+6, width:b6w-50, height:16,
  text:"🔬 PROCEDIMENTO (por tarefa)", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#22543d", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"met-proc-text", type:"text", x:b6x+25, y:metY2+24, width:b6w-50, height:125,
  text:"1. Submeter a tarefa ao agente\n   no modo designado\n\n2. Coletar o código gerado\n\n3. Executar suíte de testes\n   + checagem de alucinação\n   (varredura estática)\n\n4. Registrar tokens consumidos\n\n5. Repetir para condição\n   controle e experimental",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Análise
const metY3 = metY2 + 170;
E.push(el({ id:"met-analise-box", type:"rectangle", x:b6x+15, y:metY3, width:b6w-30, height:90,
  strokeColor:"#2f855a", backgroundColor:"#c6f6d5", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"met-analise-title", type:"text", x:b6x+25, y:metY3+6, width:b6w-50, height:16,
  text:"📊 ANÁLISE ESTATÍSTICA", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#22543d", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"met-analise-text", type:"text", x:b6x+25, y:metY3+24, width:b6w-50, height:60,
  text:"• Teste t pareado\n  (controle vs. experimental)\n\n• Tamanho de efeito (Cohen's d)\n\n• Análise qualitativa dos\n  padrões de falha",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ── B7: RESULTADOS (x:930, w:440, y:1160) — GREEN SUCCESS THEME ──
const b7x = 930, b7w = 440, b7y = 1160;
E.push(el({ id:"res-box", type:"rectangle", x:b7x, y:b7y, width:b7w, height:460,
  strokeColor:"#276749", backgroundColor:"#f0fff4", fillStyle:"solid",
  strokeWidth:1.5, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"res-title", type:"text", x:b7x+15, y:b7y+8, width:b7w-30, height:22,
  text:"RESULTADOS ESPERADOS", fontSize:13, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#276749", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));

// Row 1: 2 columns
const resColW = (b7w-60)/2;
// Col 1 — Reduções
const resR1Y = b7y + 40;
E.push(el({ id:"res-reducoes-box", type:"rectangle", x:b7x+20, y:resR1Y, width:resColW, height:150,
  strokeColor:"#38a169", backgroundColor:"#c6f6d5", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"res-reducoes-title", type:"text", x:b7x+25, y:resR1Y+6, width:resColW-10, height:16,
  text:"📉 REDUÇÕES ESPERADAS", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#22543d", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"res-meta1", type:"text", x:b7x+25, y:resR1Y+26, width:resColW-10, height:115,
  text:"🔴 ALUCINAÇÃO\n    ↓ > 40%\n    Código com funções/\n    imports inexistentes\n\n🟠 REGRESSÃO\n    ↓ > 50%\n    Quebra de código\n    já testado",
  fontSize:10, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Col 2 — Aumento
E.push(el({ id:"res-aumento-box", type:"rectangle", x:b7x+resColW+40, y:resR1Y, width:resColW, height:150,
  strokeColor:"#38a169", backgroundColor:"#c6f6d5", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"res-aumento-title", type:"text", x:b7x+resColW+45, y:resR1Y+6, width:resColW-10, height:16,
  text:"📈 AUMENTO ESPERADO", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#22543d", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"res-meta2", type:"text", x:b7x+resColW+45, y:resR1Y+26, width:resColW-10, height:115,
  text:"🟡 EFICIÊNCIA\n    DE TOKENS\n    ↑ > 30%\n    Menos tokens por\n    tarefa concluída\n\n🟢 ACERTO 1ª ITER.\n    Mais tarefas passam\n    sem loop de correção",
  fontSize:10, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Trade-off
const tradeY = resR1Y + 170;
E.push(el({ id:"res-tradeoff-box", type:"rectangle", x:b7x+20, y:tradeY, width:b7w-40, height:140,
  strokeColor:"#38a169", backgroundColor:"#f0fff4", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"res-tradeoff-title", type:"text", x:b7x+25, y:tradeY+6, width:b7w-50, height:16,
  text:"⚖️ TRADE-OFF ESPERADO", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#22543d", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"res-tradeoff-text", type:"text", x:b7x+25, y:tradeY+26, width:b7w-50, height:105,
  text:"A 1ª iteração pode ser mais lenta (custo de gerar\nas especificações via SDD), mas o ciclo total\nCONVERGE COM MENOS ITERAÇÕES e produz\ncódigo de MAIOR qualidade final.\n\nO ganho está no resultado líquido:\nmenos retrabalho + menos regressões + menos tokens\ngastos em loops de correção ineficientes.",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#22543d", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ── B8: CONTRIBUIÇÃO (x:1400, w:620, y:1160) ──
const b8x = 1400, b8w = 620, b8y = 1160;
E.push(el({ id:"contrib-box", type:"rectangle", x:b8x, y:b8y, width:b8w, height:460,
  strokeColor:"#8b7a4f", backgroundColor:"#fffff0", fillStyle:"solid",
  strokeWidth:1.2, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"contrib-title", type:"text", x:b8x+15, y:b8y+8, width:b8w-30, height:22,
  text:"CONTRIBUIÇÃO ESPERADA", fontSize:13, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#8b7a4f", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));

// Teórica (left half)
const colW8 = (b8w-60)/2;
E.push(el({ id:"contrib-teorica-box", type:"rectangle", x:b8x+20, y:b8y+40, width:colW8, height:180,
  strokeColor:"#8b7a4f", backgroundColor:"#fefcbf", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"contrib-teorica-title", type:"text", x:b8x+25, y:b8y+46, width:colW8-10, height:16,
  text:"📚 CONTRIBUIÇÃO TEÓRICA", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#6b5a2f", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"contrib-teorica", type:"text", x:b8x+25, y:b8y+66, width:colW8-10, height:148,
  text:"• Framework que traduz\n  premissas comportamentais\n  (Karpathy, 2025) em\n  mecanismos de engenharia\n  verificáveis com enforcement\n  programático\n\n• Evidência empírica sobre a\n  eficácia do metaprompting\n  arquitetural como estratégia\n  de contenção de alucinações,\n  regressões e desperdício",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Prática (right half)
E.push(el({ id:"contrib-pratica-box", type:"rectangle", x:b8x+colW8+40, y:b8y+40, width:colW8, height:180,
  strokeColor:"#8b7a4f", backgroundColor:"#fefcbf", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"contrib-pratica-title", type:"text", x:b8x+colW8+45, y:b8y+46, width:colW8-10, height:16,
  text:"🔧 CONTRIBUIÇÃO PRÁTICA", fontSize:10, fontFamily:2, textAlign:"center",
  verticalAlign:"top", strokeColor:"#6b5a2f", backgroundColor:"transparent",
  fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
E.push(el({ id:"contrib-pratica", type:"text", x:b8x+colW8+45, y:b8y+66, width:colW8-10, height:148,
  text:"• Protótipo open-source:\n  Paperclip + Hermes +\n  Test Harness integrados\n  em loop cognitivo restritivo\n\n• Reprodutível e extensível\n  a outros domínios além de\n  programação\n\n• Métricas e benchmark\n  reutilizáveis pela\n  comunidade de pesquisa",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// Relevância PLN (full width below)
const plnY = b8y + 235;
E.push(el({ id:"contrib-pln-box", type:"rectangle", x:b8x+20, y:plnY, width:b8w-40, height:200,
  strokeColor:"#8b7a4f", backgroundColor:"#fefcbf", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"contrib-pln-title", type:"text", x:b8x+25, y:plnY+8, width:b8w-50, height:16,
  text:"🎯 RELEVÂNCIA PARA PROCESSAMENTO DE LINGUAGEM NATURAL", fontSize:10, fontFamily:2,
  textAlign:"center", verticalAlign:"top", strokeColor:"#6b5a2f",
  backgroundColor:"transparent", fillStyle:"solid", strokeWidth:0, roughness:0, opacity:100 }));
const plnItems = [
  "Agentic AI — Arquitetura de orquestração com loop fechado de auto-correção",
  "Constitutional AI / Guardrails — Restrições programáticas (não apenas textuais) no comportamento do agente",
  "Prompt Engineering Estruturado — SDD como forma avançada de constrained generation",
  "Avaliação de Agentes — Test Harness como métrica objetiva de sucesso, substituindo avaliação subjetiva",
  "Eficiência Computacional — Controle de orçamento de tokens; redução de desperdício via TDD",
  "Memória e Aprendizado Contínuo — Hermes com persistência de skills entre sessões",
];
E.push(el({ id:"contrib-pln-text", type:"text", x:b8x+25, y:plnY+28, width:b8w-50, height:165,
  text:plnItems.map((t,i) => (i+1)+". "+t).join("\n"),
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"top",
  strokeColor:"#1a202c", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ═══════════════════════════════════════
// LEGEND
// ═══════════════════════════════════════
const legY = 1660;
E.push(el({ id:"legend-box", type:"rectangle", x:50, y:legY, width:1970, height:50,
  strokeColor:"#a0aec0", backgroundColor:"#f7fafc", fillStyle:"solid",
  strokeWidth:1, roughness:0, opacity:100, boundElements:null }));
E.push(el({ id:"legend-text", type:"text", x:60, y:legY+8, width:1950, height:34,
  text:"LEGENDA DE CONGRUÊNCIA:  🔴 Problemática → SDD contrata escopo e força planejamento  |  🟣 Fundamentação → TDD + Harness materializam Goal-Driven Execution  |  🟠 Hipótese → Guardrails + Sandbox garantem Surgical Changes  |  🟢 Resultados → Metas quantitativas  |  4 pilares de Karpathy (2025) traduzidos em mecanismos de engenharia com enforcement em tempo de execução",
  fontSize:9, fontFamily:2, textAlign:"left", verticalAlign:"middle",
  strokeColor:"#4a5568", backgroundColor:"transparent", fillStyle:"solid",
  strokeWidth:0, roughness:0, opacity:100 }));

// ═══════════════════════════════════════
// BUILD
// ═══════════════════════════════════════
const output = {
  type: "excalidraw",
  version: 2,
  source: "https://excalidraw.com",
  elements: E,
  appState: {
    gridSize: 20, gridStep: 5, gridModeEnabled: false,
    viewBackgroundColor: "#ffffff", lockedMultiSelections: {},
  },
  files: {},
};

const outPath = path.join(__dirname, "mapa-mental-tcc.excalidraw");
fs.writeFileSync(outPath, JSON.stringify(output, null, 2));
console.log("✅ Written", E.length, "elements to", outPath);
