FROM python:3.13-alpine

WORKDIR /app

RUN addgroup -S exporter \
    && adduser -S -G exporter exporter

COPY exporter.py /app/exporter.py

USER exporter

EXPOSE 9101

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:9101/healthz', timeout=3)"

CMD ["python", "/app/exporter.py"]
