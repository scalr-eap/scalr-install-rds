data "aws_subnet_ids" "scalr" {
  vpc_id = "${var.vpc}"
}

resource "aws_db_subnet_group" "scalr" {
  name = "scalr-db-subnet-group"
  subnet_ids = data.aws_subnet_ids.scalr.ids

  tags = {
    Name = "Group1"
  }
}

resource "aws_db_instance" "scalr_mysql" {
  allocated_storage    = 750
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.xlarge"
  name                 = "scalr"
  username             = "scalr"
  password             = random_password.mysql_pw.result
  db_subnet_group_name = aws_db_subnet_group.scalr.name
  vpc_security_group_ids = [ "${data.aws_security_group.default_sg.id}", "${aws_security_group.mysql_sg.id}","${aws_security_group.scalr_sg.id}"]
  skip_final_snapshot  = true
}

output "db_address" {
  value = aws_db_instance.scalr_mysql.address
}
