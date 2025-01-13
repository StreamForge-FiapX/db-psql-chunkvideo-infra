resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg-"
  description = "Security group for RDS instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15.10"
  instance_class       = "db.t3.micro"
  db_name              = "chunkvideodb"
  identifier           = "psql-chunkvideo-db"
  username             = "dbadminuser"
  password             = random_password.rds_password.result
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  publicly_accessible  = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_username" {
  value = aws_db_instance.postgres.username
}

output "rds_database_name" {
  value = aws_db_instance.postgres.db_name
}

resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!@#%^&*()"
}

resource "random_id" "secret_version" {
  byte_length = 4
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = "chunkvideo-dbcredentials-psql"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    db_host     = aws_db_instance.postgres.endpoint
    db_port     = 5432
    db_name     = aws_db_instance.postgres.db_name
    db_user     = aws_db_instance.postgres.username
    db_password = random_password.rds_password.result
    version_id  = random_id.secret_version.hex
  })
}



