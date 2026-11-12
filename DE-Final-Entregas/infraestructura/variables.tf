variable "aws_region" {
  description = "Región de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre del bucket S3 privado para almacenar entregas y resultados de Athena"
  type        = string
  default     = "de-final-entregas-daniel-202610"
}

variable "glue_database_name" {
  description = "Nombre de la base de datos en AWS Glue Data Catalog"
  type        = string
  default     = "de_final_entregas_db"
}

variable "glue_table_name" {
  description = "Nombre de la tabla externa en AWS Glue Data Catalog"
  type        = string
  default     = "entregas"
}

variable "athena_workgroup_name" {
  description = "Nombre del workgroup de Amazon Athena"
  type        = string
  default     = "de_final_entregas_wg"
}

variable "projection_date_range" {
  description = "Rango de fechas proyectadas (inicio,fin) en formato yyyy-MM-dd"
  type        = string
  default     = "2026-10-01,2026-10-03"
}
