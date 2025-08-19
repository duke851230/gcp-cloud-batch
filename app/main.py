import os
import time
from datetime import datetime

if __name__ == "__main__":
    run_id = os.getenv("RUN_ID", "local")
    now = datetime.now(datetime.timezone.utc).isoformat()
    print(f"[Batch] Hello from Python! run_id={run_id} utc_now={now}")
    # 模擬你的工作內容
    for i in range(3):
        print(f"working... step {i+1}/3")
        time.sleep(1)
    print("done ✅")