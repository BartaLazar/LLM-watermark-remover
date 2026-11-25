# Container image for running the web app (web/) on AWS Lambda.
# The same image also runs locally:
#   docker build -t synreplace-web .
#   docker run --rm -p 8080:8080 synreplace-web   ->  http://127.0.0.1:8080

FROM python:3.12-slim

# Lambda Web Adapter: a Lambda extension that turns Lambda's invoke events
# into plain HTTP requests to uvicorn, so the FastAPI app runs unchanged.
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:1.1.0 /lambda-adapter /opt/extensions/lambda-adapter

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    NLTK_DATA=/opt/nltk_data \
    AWS_LWA_PORT=8080 \
    AWS_LWA_READINESS_CHECK_PATH=/api/v1/health

WORKDIR /app

# Dependencies first: this layer is rebuilt only when requirements.txt changes.
COPY requirements.txt .
RUN pip install -r requirements.txt

# Bake the NLTK data into the image. Lambda's filesystem is read-only, so the
# app can't download it at runtime. Only the packages synreplace/corpora.py needs.
RUN python -m nltk.downloader -d /opt/nltk_data \
        wordnet omw-1.4 averaged_perceptron_tagger_eng cmudict

# The synreplace package itself, then the web app (backend + static frontend).
COPY pyproject.toml README.md LICENSE ./
COPY synreplace ./synreplace
RUN pip install .
COPY web ./web
RUN python -m compileall -q web/backend

WORKDIR /app/web/backend
EXPOSE 8080
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
