terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

# Создаем сеть
resource "docker_network" "saleor_backend_tier" {
  name   = "saleor-backend-tier"
  driver = "bridge"
}

# Создаем тома
resource "docker_volume" "grafana_data" {
  name = "grafana_data"
}

resource "docker_volume" "saleor_db" {
  name = "saleor-db"
}

resource "docker_volume" "saleor_redis" {
  name = "saleor-redis"
}

resource "docker_volume" "saleor_media" {
  name = "saleor-media"
}

# Сервис: db (Postgres)
resource "docker_container" "db" {
  name    = "saleor-db"
  image   = "postgres:15-alpine"
  restart = "unless-stopped"

  ports {
    internal = 5432
    external = 5432
  }

  env = [
    "POSTGRES_USER=saleor",
    "POSTGRES_PASSWORD=saleor",
  ]

  volumes {
    volume_name    = docker_volume.saleor_db.name
    container_path = "/var/lib/postgresql/data"
  }

  volumes {
    host_path      = "C:\\Users\\alanb\\OneDrive\\Рабочий стол\\saleor-platform\\terraform\\replica_user.sql"
    container_path = "/docker-entrypoint-initdb.d/replica_user.sql"
  }

  networks_advanced {
    name = docker_network.saleor_backend_tier.name
  }
}


# Сервис: redis
resource "docker_container" "redis" {
  name    = "saleor-redis"
  image   = "redis:7.0-alpine"
  restart = "unless-stopped"

  ports {
    internal = 6379
    external = 6379
  }

  volumes {
    volume_name    = docker_volume.saleor_redis.name
    container_path = "/data"
  }

  networks_advanced {
    name = docker_network.saleor_backend_tier.name
  }
}

# Сервис: api
resource "docker_container" "api" {
  name    = "saleor-api"
  image   = "ghcr.io/saleor/saleor:3.20"
  restart = "unless-stopped"

  ports {
    internal = 8000
    external = 8000
  }

  networks_advanced {
    name = docker_network.saleor_backend_tier.name
  }

  volumes {
    volume_name    = docker_volume.saleor_media.name
    container_path = "/app/media"
  }

  env = [
  "JAEGER_AGENT_HOST=jaeger",
  "DASHBOARD_URL=http://localhost:9000/",
  "ALLOWED_HOSTS=localhost,api",
  "DEFAULT_CHANNEL_SLUG=default-channel",
  "HTTP_IP_FILTER_ALLOW_LOOPBACK_IPS=True",
  "HTTP_IP_FILTER_ENABLED=True",
  "DATABASE_URL=postgresql://saleor:saleor@saleor-db:5432/saleor"
  ]

  depends_on = [
    docker_container.db,
    docker_container.redis,
  ]

  stdin_open = true
  tty        = true
}

# Сервис: worker
resource "docker_container" "worker" {
  name    = "saleor-worker"
  image   = "ghcr.io/saleor/saleor:3.20"
  restart = "unless-stopped"

  command = ["celery", "-A", "saleor", "--app=saleor.celeryconf:app", "worker", "--loglevel=info", "-B"]

  networks_advanced {
    name = docker_network.saleor_backend_tier.name
  }

  volumes {
    volume_name    = docker_volume.saleor_media.name
    container_path = "/app/media"
  }

  env = [
    "DEFAULT_CHANNEL_SLUG=default-channel",
    "HTTP_IP_FILTER_ALLOW_LOOPBACK_IPS=True",
    "HTTP_IP_FILTER_ENABLED=True"
  ]

  depends_on = [
    docker_container.redis,
  ]
}

# Сервис: dashboard
resource "docker_container" "dashboard" {
  name    = "saleor-dashboard"
  image   = "ghcr.io/saleor/saleor-dashboard:latest"
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 9000
  }

  networks_advanced {
    name = docker_network.saleor_backend_tier.name
  }
}
