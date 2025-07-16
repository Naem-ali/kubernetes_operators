# Build stage
FROM python:3.9-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Final stage
FROM python:3.9-slim

WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY redisoperator/ ./redisoperator/

ENV PATH=/root/.local/bin:$PATH
ENV PYTHONPATH=/app

USER 1001
CMD ["kopf", "run", "--standalone", "redisoperator/operator.py"]
