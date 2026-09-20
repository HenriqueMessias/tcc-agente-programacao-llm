"""Máquina de estados do ciclo cognitivo restritivo (seção 6.3) e o loop livre
do baseline (seção 6.4).

SPEC -> RED -> GREEN -> REFACTOR -> DOM_VISUAL, com no máximo 5 passagens
GREEN->DOM_VISUAL, orçamento e timeout aplicados pelo chamador (run_execution.py).
"""
import json
import time

from . import container as container_mod
from . import tools as tools_mod
from .deepseek_client import DeepSeekClient
from .logging_ import ExecutionLogger

CONTROL_TOOLS = {
    "SPEC": {
        "type": "function",
        "function": {
            "name": "submit_spec",
            "description": "Envia a especificação SDD (rotas, modelos de dados, comportamentos) como concluída para revisão do orquestrador.",
            "parameters": {"type": "object", "properties": {"spec": {"type": "string"}}, "required": ["spec"]},
        },
    },
    "RED": {
        "type": "function",
        "function": {
            "name": "submit_red",
            "description": "Sinaliza que os testes (RSpec) que codificam os critérios de aceitação foram escritos e devem ser verificados (precisam falhar, pois ainda não há implementação).",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    "GREEN": {
        "type": "function",
        "function": {
            "name": "submit_green",
            "description": "Sinaliza que a implementação está pronta e os testes da fase RED devem passar.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    "REFACTOR": {
        "type": "function",
        "function": {
            "name": "submit_refactor",
            "description": "Sinaliza que a refatoração terminou (ou que nenhuma foi necessária) e os testes continuam passando.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    "FINAL": {
        "type": "function",
        "function": {
            "name": "submit_final",
            "description": "Sinaliza que a aplicação está completa e pronta para avaliação.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
}

SPEC_KEYWORDS = ["rota", "route", "model", "modelo", "comportamento", "behavior"]

# Controle de custo/contexto: sem isso, o histórico de mensagens cresce sem
# limite ao longo das dezenas de chamadas de ferramenta por execução (saída
# de bundle install, logs de rspec, listagens de arquivo) e o custo por
# chamada explode (visto na prática: de ~2K para ~80K tokens de entrada por
# chamada em ~100 chamadas de uma única execução). Mantém o sistema + a
# instrução inicial da tarefa, e uma janela deslizante das mensagens mais
# recentes; o meio é substituído por um resumo de uma linha.
MAX_MESSAGES = 30
KEEP_HEAD = 2


def _compact_messages(messages: list[dict]) -> None:
    if len(messages) <= MAX_MESSAGES:
        return
    cut_start = len(messages) - (MAX_MESSAGES - KEEP_HEAD - 1)
    while cut_start < len(messages) and messages[cut_start]["role"] == "tool":
        cut_start += 1
    if cut_start <= KEEP_HEAD:
        return
    removed = cut_start - KEEP_HEAD
    summary = {"role": "user", "content": f"[{removed} mensagens anteriores foram omitidas do contexto para controlar o custo de tokens. O trabalho já realizado permanece no workspace (use list_files/read_file se precisar consultar); continue de onde parou.]"}
    messages[KEEP_HEAD:cut_start] = [summary]


def _validate_spec(spec_text: str) -> tuple[bool, str]:
    lowered = spec_text.lower()
    missing = [kw for kw in ("rota", "model", "comportamento") if kw not in lowered and {"rota": "route", "model": "modelo", "comportamento": "behavior"}[kw] not in lowered]
    if len(spec_text.strip()) < 100:
        return False, "especificação muito curta (< 100 caracteres)"
    if missing:
        return False, f"especificação não menciona: {', '.join(missing)}"
    return True, "ok"


async def agent_loop(client: DeepSeekClient, logger: ExecutionLogger, container: container_mod.ExecutionContainer, messages: list[dict], tools: list[dict], control_names: set[str], deadline: float, budget_usd: float, max_iterations: int = 40):
    """Roda o loop de tool-calling até o agente chamar uma ferramenta de
    controle (retorna (nome, args)) ou até estourar orçamento/timeout/iterações
    (retorna (None, None))."""
    for _ in range(max_iterations):
        if time.monotonic() > deadline:
            return None, {"reason": "timeout"}
        if client.total_cost_usd > budget_usd:
            return None, {"reason": "budget_exceeded"}

        _compact_messages(messages)

        message = await client.chat(messages, tools=tools)
        # A API do DeepSeek rejeita "tool_calls": [] (array vazio) com 400 —
        # o campo precisa ser omitido quando a resposta não chama nenhuma
        # ferramenta, não enviado como lista vazia (visto na prática: uma
        # execução de T2 perdida por "erro_infraestrutura" por causa disso).
        assistant_msg = {"role": "assistant", "content": message.content or ""}
        if message.tool_calls:
            assistant_msg["tool_calls"] = [tc.model_dump() for tc in message.tool_calls]
        messages.append(assistant_msg)
        logger.log("assistant_message", content=message.content, tool_calls=[tc.model_dump() for tc in (message.tool_calls or [])], cost_usd=client.call_log[-1]["cost_usd"], input_tokens=client.call_log[-1]["input_tokens"], output_tokens=client.call_log[-1]["output_tokens"])

        if not message.tool_calls:
            messages.append({"role": "user", "content": "Continue. Use as ferramentas disponíveis para progredir, ou chame a ferramenta de conclusão da fase quando terminar."})
            continue

        # Toda tool_use precisa de um tool_result correspondente ANTES de
        # qualquer novo conteúdo (exigência da API Anthropic) — mesmo quando
        # uma das chamadas é a ferramenta de controle da fase. Por isso,
        # respondemos a todas as chamadas do turno antes de decidir retornar.
        control_call = None
        for tool_call in message.tool_calls:
            name = tool_call.function.name
            args = json.loads(tool_call.function.arguments or "{}")
            logger.log("tool_call", name=name, args=args)

            if name in control_names:
                if control_call is None:
                    control_call = (name, args)
                result = {"ok": True, "note": "fase será avaliada após esta resposta"}
            elif name in tools_mod.FILE_TOOLS_BY_NAME:
                result = tools_mod.execute_file_tool(container, name, args)
            else:
                result = {"ok": False, "error": f"ferramenta desconhecida: {name}"}
            logger.log("tool_result", name=name, result={k: v for k, v in result.items() if k != "content" or len(str(v)) < 2000})
            messages.append({"role": "tool", "tool_call_id": tool_call.id, "content": json.dumps(result, ensure_ascii=False)[:8000]})

        if control_call is not None:
            return control_call

    return None, {"reason": "max_iterations"}


async def run_restricted_cycle(client, logger, container, base_prompt: str, deadline: float, budget_usd: float, oracle_check) -> dict:
    """Executa o ciclo SPEC->RED->GREEN->REFACTOR->DOM_VISUAL. O chamador
    (run_execution.py) injeta a validação DOM/VISUAL entre as passagens."""
    file_tools = tools_mod.FILE_TOOLS
    messages = [
        {"role": "system", "content": "Você é um agente de desenvolvimento Rails operando sob um protocolo restritivo de 5 fases: SPEC, RED, GREEN, REFACTOR, DOM_VISUAL. Você deve seguir a fase atual estritamente e usar a ferramenta de conclusão de fase indicada quando terminar."},
        {"role": "user", "content": base_prompt},
    ]

    phase_result = {"phases": []}

    # FASE 1 — SPEC
    messages.append({"role": "user", "content": "FASE ATUAL: SPEC. Produza a especificação técnica (rotas, modelos de dados, comportamentos) e chame submit_spec com o texto completo."})
    while True:
        name, args = await agent_loop(client, logger, container, messages, file_tools + [CONTROL_TOOLS["SPEC"]], {"submit_spec"}, deadline, budget_usd)
        if name is None:
            return {**phase_result, "failure": args["reason"], "phase_failed": "SPEC"}
        ok, reason = _validate_spec(args.get("spec", ""))
        logger.log("phase_transition", phase="SPEC", accepted=ok, reason=reason)
        if ok:
            phase_result["phases"].append({"phase": "SPEC", "accepted": True})
            break
        messages.append({"role": "user", "content": f"Especificação rejeitada: {reason}. Revise e chame submit_spec novamente."})

    # FASE 2 — RED
    messages.append({"role": "user", "content": "FASE ATUAL: RED. Escreva os testes RSpec que codificam os critérios de aceitação (ainda sem implementação). Rode bundle exec rspec com run_command para confirmar que falham. Depois chame submit_red."})
    while True:
        name, args = await agent_loop(client, logger, container, messages, file_tools + [CONTROL_TOOLS["RED"]], {"submit_red"}, deadline, budget_usd)
        if name is None:
            return {**phase_result, "failure": args["reason"], "phase_failed": "RED"}
        rspec = container_mod.run_command(container, "bundle exec rspec 2>&1", timeout_s=180)
        logger.log("oracle_check", phase="RED", exit_code=rspec["exit_code"])
        if rspec["exit_code"] != 0:
            phase_result["phases"].append({"phase": "RED", "accepted": True})
            break
        messages.append({"role": "user", "content": "Os testes passaram sem implementação — isso não é válido para a fase RED. Ajuste os testes para que falhem corretamente e chame submit_red de novo."})

    # FASE 3 — GREEN / FASE 4 — REFACTOR / FASE 5 — DOM_VISUAL (loop de até 5 passagens)
    for pass_number in range(1, 6):
        messages.append({"role": "user", "content": f"FASE ATUAL: GREEN (passagem {pass_number}/5). Implemente até os testes da fase RED passarem. Chame submit_green quando terminar."})
        name, args = await agent_loop(client, logger, container, messages, file_tools + [CONTROL_TOOLS["GREEN"]], {"submit_green"}, deadline, budget_usd)
        if name is None:
            return {**phase_result, "failure": args["reason"], "phase_failed": f"GREEN_pass{pass_number}"}
        rspec = container_mod.run_command(container, "bundle exec rspec 2>&1", timeout_s=180)
        logger.log("oracle_check", phase="GREEN", pass_number=pass_number, exit_code=rspec["exit_code"])
        if rspec["exit_code"] != 0:
            messages.append({"role": "user", "content": f"Os testes ainda falham:\n{rspec['stdout'][-3000:]}\nContinue ajustando e chame submit_green novamente."})
            continue
        phase_result["phases"].append({"phase": "GREEN", "pass": pass_number, "accepted": True})

        messages.append({"role": "user", "content": "FASE ATUAL: REFACTOR. Reorganize o código se necessário, mantendo os testes passando. Chame submit_refactor quando terminar (pode chamar imediatamente se nenhuma refatoração for necessária)."})
        name, args = await agent_loop(client, logger, container, messages, file_tools + [CONTROL_TOOLS["REFACTOR"]], {"submit_refactor"}, deadline, budget_usd)
        if name is None:
            return {**phase_result, "failure": args["reason"], "phase_failed": f"REFACTOR_pass{pass_number}"}
        rspec = container_mod.run_command(container, "bundle exec rspec 2>&1", timeout_s=180)
        logger.log("oracle_check", phase="REFACTOR", pass_number=pass_number, exit_code=rspec["exit_code"])
        phase_result["phases"].append({"phase": "REFACTOR", "pass": pass_number, "tests_pass_after": rspec["exit_code"] == 0})

        container_mod.start_rails_server(container)
        dom_visual_report = await oracle_check(container)
        phase_result["phases"].append({"phase": "DOM_VISUAL", "pass": pass_number, **dom_visual_report})
        if dom_visual_report.get("passed"):
            phase_result["success"] = True
            return phase_result
        messages.append({"role": "user", "content": f"FASE DOM_VISUAL reprovou nesta passagem. Relatório de diferenças:\n{json.dumps(dom_visual_report.get('diff_report', {}), ensure_ascii=False)[:3000]}\nVolte para GREEN e corrija."})

    phase_result["failure"] = "max_dom_visual_passes"
    return phase_result


async def run_baseline_cycle(client, logger, container, base_prompt: str, deadline: float, budget_usd: float) -> dict:
    """Fluxo livre: mesmo prompt-base com os critérios de aceitação, sem fases obrigatórias nem gates."""
    messages = [
        {"role": "system", "content": "Você é um agente de desenvolvimento Rails. Implemente a aplicação solicitada da forma que julgar melhor."},
        {"role": "user", "content": base_prompt + "\n\nQuando terminar a implementação, chame submit_final."},
    ]
    name, args = await agent_loop(client, logger, container, messages, tools_mod.FILE_TOOLS + [CONTROL_TOOLS["FINAL"]], {"submit_final"}, deadline, budget_usd, max_iterations=80)
    if name is None:
        return {"failure": args["reason"]}
    return {"success": True}
