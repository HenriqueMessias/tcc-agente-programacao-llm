"""Ciclo de vida do contêiner Docker por execução (secao 6.6 do protocolo).

Cada execucao roda em um container Rails novo, com um diretorio de host
unico bind-montado em /workspace (evita docker cp: o orquestrador le/escreve
os arquivos diretamente pelo filesystem do host para logging/diff).
"""
import shutil
import socket
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

IMAGE = "tcc-rails-runner:latest"


@dataclass
class ExecutionContainer:
    execution_id: str
    container_id: str
    workspace_host: Path
    host_port: int


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("", 0))
        return s.getsockname()[1]


def start(execution_id: str, results_dir: Path) -> ExecutionContainer:
    workspace_host = results_dir / execution_id / "workspace"
    workspace_host.mkdir(parents=True, exist_ok=True)
    host_port = _free_port()

    run = subprocess.run(
        [
            "docker", "run", "-d",
            "--name", f"exec-{execution_id}",
            "-v", f"{workspace_host.resolve()}:/workspace",
            "-p", f"{host_port}:3000",
            IMAGE,
        ],
        capture_output=True, text=True, check=True,
    )
    container_id = run.stdout.strip()

    subprocess.run(["docker", "exec", container_id, "git", "init", "-q", "/workspace"], check=True)
    subprocess.run(["docker", "exec", container_id, "git", "-C", "/workspace", "config", "user.email", "orchestrator@experiment.local"], check=True)
    subprocess.run(["docker", "exec", container_id, "git", "-C", "/workspace", "config", "user.name", "orchestrator"], check=True)

    return ExecutionContainer(execution_id=execution_id, container_id=container_id, workspace_host=workspace_host, host_port=host_port)


def run_command(container: ExecutionContainer, cmd: str, timeout_s: int = 120) -> dict:
    started = time.monotonic()
    try:
        result = subprocess.run(
            ["docker", "exec", "-w", "/workspace", container.container_id, "sh", "-c", cmd],
            capture_output=True, text=True, timeout=timeout_s,
        )
        return {
            "cmd": cmd,
            "exit_code": result.returncode,
            "stdout": result.stdout[-2500:],
            "stderr": result.stderr[-2500:],
            "elapsed_s": time.monotonic() - started,
            "timed_out": False,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "cmd": cmd,
            "exit_code": None,
            "stdout": (exc.stdout or "")[-2500:] if isinstance(exc.stdout, str) else "",
            "stderr": (exc.stderr or "")[-2500:] if isinstance(exc.stderr, str) else "",
            "elapsed_s": time.monotonic() - started,
            "timed_out": True,
        }


def start_rails_server(container: ExecutionContainer) -> None:
    # Mata qualquer servidor anterior ainda vivo na porta 3000 antes de subir
    # um novo — necessário porque o agente às vezes sobe seu próprio `rails
    # server` manualmente (para testar) e tenta encerrá-lo com `pkill`, que
    # não existe na imagem (slim, sem procps); o processo órfão fica
    # ocupando a porta e o servidor "oficial" do orquestrador nunca consegue
    # bindar, causando ERR_EMPTY_RESPONSE na avaliação (visto na prática).
    run_command(container, "if [ -f tmp/pids/server.pid ]; then kill -9 $(cat tmp/pids/server.pid) 2>/dev/null; rm -f tmp/pids/server.pid; fi", timeout_s=15)
    run_command(container, "RAILS_ENV=development bin/rails server -b 0.0.0.0 -p 3000 -d -P /workspace/tmp/pids/server.pid", timeout_s=60)
    # Espera ativa em vez de sleep fixo: um `sleep(3)` cego falha quando o
    # boot demora mais (eager load em development, primeira compilação de
    # assets) sem sinalizar o problema.
    for _ in range(20):
        check = run_command(container, "curl -s -o /dev/null -w '%{http_code}' --max-time 2 http://127.0.0.1:3000/ 2>/dev/null || true", timeout_s=10)
        if check["stdout"].strip() not in ("", "000"):
            return
        time.sleep(1)


def stop(container: ExecutionContainer, keep_workspace: bool = True) -> None:
    subprocess.run(["docker", "rm", "-f", container.container_id], capture_output=True)
    if not keep_workspace:
        shutil.rmtree(container.workspace_host, ignore_errors=True)
