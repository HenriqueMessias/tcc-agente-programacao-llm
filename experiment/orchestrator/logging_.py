"""Log estruturado JSONL por execução (secao 6.6): prompts, mensagens, tool
calls, diffs, commits, erros, custo por chamada, timestamps."""
import json
import time
from pathlib import Path


class ExecutionLogger:
    def __init__(self, results_dir: Path, execution_id: str) -> None:
        self.path = results_dir / execution_id / "log.jsonl"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._fh = self.path.open("a", encoding="utf-8")

    def log(self, event_type: str, **fields) -> None:
        record = {"ts": time.time(), "event": event_type, **fields}
        self._fh.write(json.dumps(record, ensure_ascii=False, default=str) + "\n")
        self._fh.flush()

    def close(self) -> None:
        self._fh.close()
