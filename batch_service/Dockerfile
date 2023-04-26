FROM python:3.7-slim

WORKDIR /app

RUN apt-get -qq update && apt-get install -y build-essential \
    libssl-dev groff \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY batch_service.py main.py

CMD ["python3", "main.py"]