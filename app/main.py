import os
import time
from datetime import datetime, timezone

if __name__ == "__main__":
    run_id: str = os.getenv("RUN_ID", "local")
    now: str = datetime.now(timezone.utc).isoformat()
    print(f"[Batch] Hello from Python! run_id={run_id} utc_now={now}")
    
    num_steps: int = 10
    for i in range(num_steps):
        print(f"working... step {i+1}/{num_steps}")
        time.sleep(1)
    print("done ✅")