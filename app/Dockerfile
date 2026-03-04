# Imagem base Python
FROM python:3.11-slim

# Define o diretório de trabalho
WORKDIR /app

# Instala dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copia e instala as dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o código da aplicação
COPY main.py .

# Expõe a porta padrão do Streamlit
EXPOSE 8501

# Comando para rodar o Streamlit
# --server.address=0.0.0.0 permite acesso externo
# --server.headless=true roda sem navegador
CMD ["streamlit", "run", "main.py", "--server.address=0.0.0.0", "--server.headless=true"]
