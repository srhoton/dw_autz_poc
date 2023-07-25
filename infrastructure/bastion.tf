resource "aws_security_group" "authz-poc_bastion_inbound" {
  name = "authz-poc_bastion_inbound"
  vpc_id = module.default_network.vpc_id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3000
    to_port = 3000
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
    Name = "authz-poc_bastion_inbound"
  }
}

resource "aws_instance" "bastion_instance" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "m5.large"
  associate_public_ip_address = true

  subnet_id = module.default_network.public_subnet_list[0]
  vpc_security_group_ids = [aws_security_group.authz-poc_bastion_inbound.id]
  key_name = "authz-poc"

  tags = {
    Name = "authz-poc_bastion"
  }
}
