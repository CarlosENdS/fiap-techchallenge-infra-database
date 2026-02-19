# db-init.tf - Database Initialization via Kubernetes Jobs
# Creates namespaces, ConfigMaps, and Jobs to seed both databases

# ==============================================================================
# NAMESPACE
# ==============================================================================

resource "kubernetes_namespace_v1" "db_init_ns" {
  metadata {
    name = "db-init"
    labels = {
      purpose = "database-initialization"
    }
  }
}

# ==============================================================================
# CONFIGMAPS - SQL Scripts
# ==============================================================================

resource "kubernetes_config_map_v1" "cargarage_seed_script" {
  metadata {
    name      = "cargarage-seed-script"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  data = {
    "seed-cargarage.sql" = file("${path.module}/scripts/seed-cargarage.sql")
  }
}

resource "kubernetes_config_map_v1" "os_service_init_script" {
  metadata {
    name      = "os-service-init-script"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  data = {
    "init-os-service-db.sql" = file("${path.module}/scripts/init-os-service-db.sql")
  }
}

resource "kubernetes_config_map_v1" "os_service_seed_script" {
  metadata {
    name      = "os-service-seed-script"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  data = {
    "seed-os-service.sql" = file("${path.module}/scripts/seed-os-service.sql")
  }
}

resource "kubernetes_config_map_v1" "execution_service_init_script" {
  metadata {
    name      = "execution-service-init-script"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  data = {
    "init-execution-service-db.sql" = file("${path.module}/scripts/init-execution-service-db.sql")
  }
}

resource "kubernetes_config_map_v1" "execution_service_seed_script" {
  metadata {
    name      = "execution-service-seed-script"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  data = {
    "seed-execution-service.sql" = file("${path.module}/scripts/seed-execution-service.sql")
  }
}

# ==============================================================================
# JOB 1 - Cargarage Database Seed (Monolito)
# ==============================================================================

resource "kubernetes_job_v1" "cargarage_db_seed" {
  metadata {
    name      = "cargarage-db-seed"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  spec {
    ttl_seconds_after_finished = 300 # Clean up job after 5 minutes

    template {
      metadata {
        labels = {
          app      = "cargarage-db-seed"
          database = "cargarage"
        }
      }
      spec {
        container {
          name    = "db-seed"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "echo 'Seeding cargarage database...' && psql -h ${aws_db_instance.postgres.address} -U ${local.db_username} -d ${local.db_name} -f /scripts/seed-cargarage.sql && echo 'Cargarage database seeded successfully!'"
          ]
          env {
            name  = "PGPASSWORD"
            value = local.db_password
          }
          volume_mount {
            name       = "sql-volume"
            mount_path = "/scripts"
          }
          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
        volume {
          name = "sql-volume"
          config_map {
            name = kubernetes_config_map_v1.cargarage_seed_script.metadata[0].name
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    aws_db_instance.postgres,
    kubernetes_config_map_v1.cargarage_seed_script
  ]

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# ==============================================================================
# JOB 2 - OS Service Database Init (Create database and user)
# ==============================================================================

resource "kubernetes_job_v1" "os_service_db_init" {
  metadata {
    name      = "os-service-db-init"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  spec {
    ttl_seconds_after_finished = 300

    template {
      metadata {
        labels = {
          app      = "os-service-db-init"
          database = "os-service"
          phase    = "init"
        }
      }
      spec {
        container {
          name    = "db-init"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "echo 'Creating os_service_db database and user...' && psql -h ${aws_db_instance.postgres.address} -U ${local.db_username} -d ${local.db_name} -f /scripts/init-os-service-db.sql || true && echo 'Database creation completed!'"
          ]
          env {
            name  = "PGPASSWORD"
            value = local.db_password
          }
          volume_mount {
            name       = "sql-volume"
            mount_path = "/scripts"
          }
          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
        volume {
          name = "sql-volume"
          config_map {
            name = kubernetes_config_map_v1.os_service_init_script.metadata[0].name
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    aws_db_instance.postgres,
    kubernetes_config_map_v1.os_service_init_script,
    kubernetes_job_v1.cargarage_db_seed
  ]

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# ==============================================================================
# JOB 3 - OS Service Database Seed
# ==============================================================================

resource "kubernetes_job_v1" "os_service_db_seed" {
  metadata {
    name      = "os-service-db-seed"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  spec {
    ttl_seconds_after_finished = 300

    template {
      metadata {
        labels = {
          app      = "os-service-db-seed"
          database = "os-service"
          phase    = "seed"
        }
      }
      spec {
        container {
          name    = "db-seed"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "echo 'Seeding os_service_db database...' && psql -h ${aws_db_instance.postgres.address} -U ${local.os_service_db_username} -d ${local.os_service_db_name} -f /scripts/seed-os-service.sql && echo 'OS Service database seeded successfully!'"
          ]
          env {
            name  = "PGPASSWORD"
            value = local.os_service_db_password
          }
          volume_mount {
            name       = "sql-volume"
            mount_path = "/scripts"
          }
          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
        volume {
          name = "sql-volume"
          config_map {
            name = kubernetes_config_map_v1.os_service_seed_script.metadata[0].name
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    aws_db_instance.postgres,
    kubernetes_config_map_v1.os_service_seed_script,
    kubernetes_job_v1.os_service_db_init
  ]

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# ==============================================================================
# JOB 4 - Execution Service Database Init (Create database and user)
# ==============================================================================

resource "kubernetes_job_v1" "execution_service_db_init" {
  metadata {
    name      = "execution-service-db-init"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  spec {
    ttl_seconds_after_finished = 300

    template {
      metadata {
        labels = {
          app      = "execution-service-db-init"
          database = "execution-service"
          phase    = "init"
        }
      }
      spec {
        container {
          name    = "db-init"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "echo 'Creating execution_service_db database and user...' && psql -h ${aws_db_instance.postgres.address} -U ${local.db_username} -d ${local.db_name} -f /scripts/init-execution-service-db.sql || true && echo 'Database creation completed!'"
          ]
          env {
            name  = "PGPASSWORD"
            value = local.db_password
          }
          volume_mount {
            name       = "sql-volume"
            mount_path = "/scripts"
          }
          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
        volume {
          name = "sql-volume"
          config_map {
            name = kubernetes_config_map_v1.execution_service_init_script.metadata[0].name
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    aws_db_instance.postgres,
    kubernetes_config_map_v1.execution_service_init_script,
    kubernetes_job_v1.os_service_db_seed
  ]

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# ==============================================================================
# JOB 5 - Execution Service Database Seed
# ==============================================================================

resource "kubernetes_job_v1" "execution_service_db_seed" {
  metadata {
    name      = "execution-service-db-seed"
    namespace = kubernetes_namespace_v1.db_init_ns.metadata[0].name
  }

  spec {
    ttl_seconds_after_finished = 300

    template {
      metadata {
        labels = {
          app      = "execution-service-db-seed"
          database = "execution-service"
          phase    = "seed"
        }
      }
      spec {
        container {
          name    = "db-seed"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "echo 'Seeding execution_service_db database...' && psql -h ${aws_db_instance.postgres.address} -U ${local.execution_service_db_username} -d ${local.execution_service_db_name} -f /scripts/seed-execution-service.sql && echo 'Execution Service database seeded successfully!'"
          ]
          env {
            name  = "PGPASSWORD"
            value = local.execution_service_db_password
          }
          volume_mount {
            name       = "sql-volume"
            mount_path = "/scripts"
          }
          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
        volume {
          name = "sql-volume"
          config_map {
            name = kubernetes_config_map_v1.execution_service_seed_script.metadata[0].name
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    aws_db_instance.postgres,
    kubernetes_config_map_v1.execution_service_seed_script,
    kubernetes_job_v1.execution_service_db_init
  ]

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}
