output "bucket_name" {
  description = "Nombre del bucket S3 creado para el ejercicio"
  value       = aws_s3_bucket.entregas.bucket
}

output "glue_database_name" {
  description = "Nombre de la base de datos en Glue Data Catalog"
  value       = aws_glue_catalog_database.entregas.name
}

output "glue_table_name" {
  description = "Nombre de la tabla externa en Glue Data Catalog"
  value       = aws_glue_catalog_table.entregas.name
}

output "athena_workgroup_name" {
  description = "Nombre del workgroup de Amazon Athena"
  value       = aws_athena_workgroup.entregas.name
}
