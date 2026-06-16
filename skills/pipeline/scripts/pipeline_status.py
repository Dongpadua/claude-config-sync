"""Pipeline run log manager."""
import os, json, sys
from datetime import datetime

PIPELINE_DIR = ".pipeline"

def init_run(issue_url: str, repo: str) -> str:
    """Create a new pipeline run log."""
    os.makedirs(PIPELINE_DIR, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    run_id = f"run-{ts}"
    log = {
        "run_id": run_id,
        "issue_url": issue_url,
        "repo": repo,
        "started": datetime.now().isoformat(),
        "stages": {},
        "status": "running"
    }
    with open(f"{PIPELINE_DIR}/{run_id}.json", "w") as f:
        json.dump(log, f, indent=2, ensure_ascii=False)
    print(f"Pipeline started: {run_id}")
    return run_id

def stage_done(run_id: str, stage: str, result: dict):
    """Record stage completion."""
    path = f"{PIPELINE_DIR}/{run_id}.json"
    with open(path) as f:
        log = json.load(f)
    log["stages"][stage] = {
        "completed": datetime.now().isoformat(),
        "result": result
    }
    with open(path, "w") as f:
        json.dump(log, f, indent=2, ensure_ascii=False)
    print(f"[{stage}] done")

def finish(run_id: str, pr_url: str = ""):
    """Mark pipeline complete."""
    path = f"{PIPELINE_DIR}/{run_id}.json"
    with open(path) as f:
        log = json.load(f)
    log["status"] = "completed"
    log["completed"] = datetime.now().isoformat()
    log["pr_url"] = pr_url
    with open(path, "w") as f:
        json.dump(log, f, indent=2, ensure_ascii=False)
    print(f"Pipeline complete: {pr_url}")

def status(run_id: str = None):
    """Print pipeline status."""
    if run_id:
        path = f"{PIPELINE_DIR}/{run_id}.json"
        with open(path) as f:
            log = json.load(f)
        print(json.dumps(log, indent=2, ensure_ascii=False))
    else:
        runs = sorted(os.listdir(PIPELINE_DIR)) if os.path.exists(PIPELINE_DIR) else []
        for r in runs[-5:]:
            with open(f"{PIPELINE_DIR}/{r}") as f:
                log = json.load(f)
            stages_done = len([s for s in log["stages"].values() if "completed" in s])
            print(f"{log['run_id']} | {log['status']} | {stages_done}/6 stages | {log.get('issue_url','N/A')[:60]}")

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "init":
        init_run(sys.argv[2], sys.argv[3])
    elif cmd == "stage":
        stage_done(sys.argv[2], sys.argv[3], json.loads(sys.argv[4]) if len(sys.argv) > 4 else {})
    elif cmd == "finish":
        finish(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "")
    else:
        status(sys.argv[2] if len(sys.argv) > 2 else None)
