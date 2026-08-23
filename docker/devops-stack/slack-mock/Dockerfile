FROM python:3.13-alpine

WORKDIR /app

COPY receiver.py /app/receiver.py

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=3)"

CMD ["python", "-u", "/app/receiver.py"]
