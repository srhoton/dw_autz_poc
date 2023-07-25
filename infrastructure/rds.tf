resource "aws_security_group" "authz-poc_rds_inbound" {
  name = "authz-poc_rds_inbound"
  vpc_id = module.default_network.vpc_id
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0 
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "authz_rds_inbound"
  }
}

resource "aws_db_subnet_group" "authz_subnet_group" {
  name = "authz_subnet_group"
  subnet_ids = module.default_network.private_subnet_list
  tags = {
    Name = "authz_subnet_group"
  }
}

resource "aws_rds_cluster" "authz_rds_cluster" {
  cluster_identifier = "authz-rds-cluster"
  engine = "aurora-postgresql"
  engine_mode = "provisioned"
  engine_version = "15.3"
  database_name = "authz"
  master_username = "authz_admin"
  master_password = "wochild1"
  db_subnet_group_name = aws_db_subnet_group.authz_subnet_group.id
  vpc_security_group_ids = [aws_security_group.authz-poc_rds_inbound.id]

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "authz_rds_instance" {
  cluster_identifier = aws_rds_cluster.authz_rds_cluster.id
  instance_class = "db.serverless"
  engine = aws_rds_cluster.authz_rds_cluster.engine
  engine_version = aws_rds_cluster.authz_rds_cluster.engine_version
  db_subnet_group_name = aws_rds_cluster.authz_rds_cluster.db_subnet_group_name
}
