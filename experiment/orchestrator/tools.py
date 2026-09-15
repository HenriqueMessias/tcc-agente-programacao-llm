"""Ferramentas expostas ao agente via tool-calling (compatível com a API DeepSeek/OpenAI)."""
from pathlib import Path

from . import container as container_mod

FILE_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "write_file",
            "description": "Cria ou sobrescreve um arquivo no workspace do projeto Rails.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Caminho relativo ao workspace, ex: app/models/book.rb"},
                    "content": {"type": "string", "description": "Conteúdo completo do arquivo"},
                },
                "required": ["path", "content"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Lê o conteúdo de um arquivo existente no workspace.",
            "parameters": {
                "type": "object",
                "properties": {"path": {"type": "string"}},
                "required": ["path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_files",
            "description": "Lista arquivos e diretórios sob um caminho do workspace.",
            "parameters": {
                "type": "object",
                "properties": {"path": {"type": "string", "description": "Caminho relativo; use '.' para a raiz"}},
                "required": ["path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "run_command",
            "description": "Executa um comando de shell no workspace (ex: 'bin/rails generate model Book', 'bundle install', 'bundle exec rspec'). Roda dentro do container isolado.",
            "parameters": {
                "type": "object",
                "properties": {
                    "cmd": {"type": "string"},
                    "timeout_s": {"type": "integer", "description": "Timeout em segundos (padrão 120)"},
                },
                "required": ["cmd"],
            },
        },
    },
]


FILE_TOOLS_BY_NAME = {t["function"]["name"] for t in FILE_TOOLS}


def _safe_path(workspace_host: Path, rel_path: str) -> Path:
    target = (workspace_host / rel_path).resolve()
    if workspace_host.resolve() not in target.parents and target != workspace_host.resolve():
        raise ValueError(f"caminho fora do workspace: {rel_path}")
    return target


def execute_file_tool(container: container_mod.ExecutionContainer, name: str, args: dict) -> dict:
    if name == "write_file":
        target = _safe_path(container.workspace_host, args["path"])
        target.parent.mkdir(parents=True, exist_ok=True)
        previous = target.read_text(encoding="utf-8", errors="replace") if target.exists() else None
        target.write_text(args["content"], encoding="utf-8")
        return {"ok": True, "path": args["path"], "bytes_written": len(args["content"]), "previous_existed": previous is not None}

    if name == "read_file":
        target = _safe_path(container.workspace_host, args["path"])
        if not target.exists():
            return {"ok": False, "error": f"arquivo não encontrado: {args['path']}"}
        content = target.read_text(encoding="utf-8", errors="replace")
        if len(content) > 4000:
            content = content[:4000] + f"\n[... arquivo truncado, {len(content)} caracteres no total; leia em partes se precisar de mais ...]"
        return {"ok": True, "path": args["path"], "content": content}

    if name == "list_files":
        target = _safe_path(container.workspace_host, args.get("path", "."))
        if not target.exists():
            return {"ok": False, "error": f"caminho não encontrado: {args.get('path', '.')}"}
        entries = sorted(str(p.relative_to(container.workspace_host)) for p in target.rglob("*") if ".git" not in p.parts and "bundle" not in p.parts)
        return {"ok": True, "entries": entries[:200], "total_found": len(entries)}

    if name == "run_command":
        result = container_mod.run_command(container, args["cmd"], timeout_s=args.get("timeout_s", 120))
        return {"ok": result["exit_code"] == 0, **result}

    raise ValueError(f"ferramenta desconhecida: {name}")
