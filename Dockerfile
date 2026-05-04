# Tutorial Avanzado de DevSecOps — Dockerfile con problemas intencionales
# Este fichero tiene 4 problemas de seguridad que deberás corregir en el Paso 4.

# ❌ PROBLEMA 1: Imagen base con CVEs conocidos (EOL desde abril 2023)
FROM ubuntu:18.04
# ✅ CORRECCIÓN 1: Imagen base con soporte activo
FROM python:3.12-slim

# Instalar dependencias del sistema
RUN apt-get update && \
    # Instalar solo lo necesario, sin caché
    apt-get install -y --no-install-recommends curl && \
    apt-get install -y python3 python3-pip curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# ✅ CORRECCIÓN 2: Crear usuario sin privilegios - Sin directiva USER el proceso se ejecuta como root
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser && \
    chown -R appuser:appgroup /app

# ✅ CORRECCIÓN 3: Ejecutar como usuario sin privilegios (no root)
USER appuser

# ✅ CORRECCIÓN 4: Healthcheck para que Kubernetes sepa el estado real - Sin HEALTHCHECK Kubernetes/Docker no sabe si la app está realmente funcionando
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

EXPOSE 5000

CMD ["python3", "src/app.py"]

# NOTA: Las variables de entorno (API_KEY, DB_PASSWORD) se pasan en runtime:
#   docker run -e API_KEY=... -e DB_PASSWORD=... tutorial-app
#   O desde un orquestador (Kubernetes Secret, Azure Key Vault CSI driver)
