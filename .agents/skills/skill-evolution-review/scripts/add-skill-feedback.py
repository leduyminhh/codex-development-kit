from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO_ROOT / "scripts" / "lib"))

from codex_config import CodexConfig, now_ho_chi_minh


def write_state(root: Path, state_path: str, reason: str, agent_name: str, target_name: str, feedback_file: Path, skill_names: list[str], outcome: str, severity: str) -> None:
    state_root = root / (state_path or "audit/skill-upgrade-state")
    state_root.mkdir(parents=True, exist_ok=True)
    now = now_ho_chi_minh()
    log_file = state_root / f"{now.strftime('%Y%m%d')}_skill-upgrade-state.jsonl"
    record = {
        "schema": "codex.skill-upgrade.state.v1",
        "timestamp": now.isoformat(timespec="seconds"),
        "phase": "capture",
        "status": "completed",
        "reason": reason,
        "agentName": agent_name,
        "targetAgent": target_name,
        "feedbackFile": str(feedback_file),
        "skillNames": skill_names,
        "outcome": outcome,
        "severity": severity,
    }
    with log_file.open("a", encoding="utf-8", newline="\n") as fh:
        fh.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(REPO_ROOT))
    parser.add_argument("--agent-name", required=True)
    parser.add_argument("--skill-names", nargs="*", default=[])
    parser.add_argument("--target-type", choices=["skill", "agent"], default="skill")
    parser.add_argument("--target-name", default="")
    parser.add_argument("--outcome", choices=["correct", "wrong", "mixed"], default="mixed")
    parser.add_argument("--severity", choices=["low", "medium", "high"], default="medium")
    parser.add_argument("--reproducible", action="store_true")
    parser.add_argument("--evidence-key", default="")
    parser.add_argument("--task-summary", required=True)
    parser.add_argument("--correct-notes", default="")
    parser.add_argument("--wrong-notes", default="")
    parser.add_argument("--missing-notes", default="")
    args = parser.parse_args()

    if not any([args.correct_notes.strip(), args.wrong_notes.strip(), args.missing_notes.strip()]):
        raise SystemExit("At least one of CorrectNotes, WrongNotes, or MissingNotes is required.")

    root = Path(args.root).resolve()
    config = CodexConfig.load(root)
    feedback_path = config.get_str("skill_upgrade", "feedbackPath", default="audit/skill-feedback") or "audit/skill-feedback"
    state_path = config.get_str("skill_upgrade", "statePath", default="audit/skill-upgrade-state") or "audit/skill-upgrade-state"
    feedback_root = root / feedback_path
    feedback_root.mkdir(parents=True, exist_ok=True)

    now = now_ho_chi_minh()
    feedback_file = feedback_root / f"{now.strftime('%Y%m%d')}_skill-feedback.jsonl"
    target_name = args.target_name.strip() or args.agent_name
    entry = {
        "timestamp": now.isoformat(timespec="seconds"),
        "agentName": args.agent_name,
        "skillNames": [name for name in args.skill_names if name.strip()],
        "targetType": args.target_type,
        "targetName": target_name,
        "outcome": args.outcome,
        "severity": args.severity,
        "reproducible": bool(args.reproducible),
        "evidenceKey": args.evidence_key.strip(),
        "taskSummary": args.task_summary,
        "correctNotes": args.correct_notes,
        "wrongNotes": args.wrong_notes,
        "missingNotes": args.missing_notes,
    }
    with feedback_file.open("a", encoding="utf-8", newline="\n") as fh:
        fh.write(json.dumps(entry, ensure_ascii=False, separators=(",", ":")) + "\n")
    write_state(
        root,
        state_path,
        "feedback_added",
        args.agent_name,
        target_name,
        feedback_file,
        entry["skillNames"],
        args.outcome,
        args.severity,
    )

    print(feedback_file)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(exc, file=sys.stderr)
        raise
