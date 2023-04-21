resource "aws_db_subnet_group" "db_private_subnet_group" {
  count      = var.publicly_accessible == false ? 1: 0
  name       = "${var.name}-db-private-subnet"
  subnet_ids = "${aws_subnet.privatesubnets.*.id}"
  tags = {
    Name = "${var.name}-db-subnet"
  }
}

resource "aws_db_subnet_group" "db_public_subnet_group" {
  count      = var.publicly_accessible == true ? 1: 0
  name       = "${var.name}-db-public-subnet"
  subnet_ids = "${aws_subnet.publicsubnets.*.id}"
  tags = {
    Name = "${var.name}-db-subnet"
  }
}


resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  vpc_id      = aws_vpc.nbc_vpc.id
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "private_rds_db" {
  count = var.enable_db && var.private_only == true ? var.db_instance_count : 0
  identifier             = "${var.name}"
  instance_class         = var.db_instance_type
  allocated_storage      = var.db_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  db_name                = var.db_name
  username               = var.username
  password               = var.db_password
  db_subnet_group_name   = "${var.name}-db-private-subnet"
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = var.skip_final_snapshot
}

resource "aws_db_instance" "public_rds_db" {
  count = var.enable_db && var.publicly_accessible == true ? var.db_instance_count : 0
  identifier             = "${var.name}"
  instance_class         = var.db_instance_type
  allocated_storage      = var.db_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  db_name                = var.db_name
  username               = var.username
  password               = var.db_password
  db_subnet_group_name   = "${var.name}-db-public-subnet"
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = var.skip_final_snapshot
}