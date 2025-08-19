FROM python:3.12-slim
WORKDIR /app
COPY app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ .
# 預設執行你的腳本（可改成你要的 entrypoint/commands）
CMD ["python", "main.py"]