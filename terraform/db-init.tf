# 1. Define o Namespace exclusivo para a tarefa de população
resource "kubernetes_namespace" "db_init_ns" {
  metadata {
    name = "db-init" # Você pode mudar para "cargarage" se preferir tudo junto
  }
}

# 2. ConfigMap dentro do namespace específico
resource "kubernetes_configmap" "db_seed_script" {
  metadata {
    name      = "db-seed-script"
    namespace = kubernetes_namespace.db_init_ns.metadata[0].name
  }

  data = {
    "seed.sql" = file("${path.module}/scripts/seed.sql")
  }
}

# 3. Job dentro do namespace específico
resource "kubernetes_job" "db_seed_job" {
  metadata {
    name      = "cargarage-db-seed"
    namespace = kubernetes_namespace.db_init_ns.metadata[0].name
  }

  spec {
    # Apaga o Job do cluster 10 segundos após terminar com sucesso
    ttl_seconds_after_finished = 10 

    template {
      metadata {
        labels = {
          app = "cargarage-db-seed"
        }
      }
      spec {
        container {
          name    = "db-seed"
          image   = "postgres:16"
          command = ["/bin/sh", "-c"]
          args = [
            "psql -h ${aws_db_instance.postgres.address} -U ${aws_db_instance.postgres.username} -d ${aws_db_instance.postgres.db_name} -f /scripts/seed.sql"
          ]
          env {
            name  = "PGPASSWORD"
            value = aws_db_instance.postgres.password
          }
          volume_mount {
            name       = "sql-volume"
            mount_path = "/scripts"
          }
        }
        volume {
          name = "sql-volume"
          config_map {
            name = "db-seed-script"
          }
        }
        restart_policy = "Never"
      }
    }
  }

  depends_on = [
    aws_db_instance.postgres,
    kubernetes_configmap.db_seed_script
  ]
}