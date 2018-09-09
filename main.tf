
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "192.168.0.0/16"
}

resource "aws_internet_gateway" "test-igw" {
  vpc_id = "${aws_vpc.test-vpc.id}"
}

resource "aws_route" "internet-access" {
  route_table_id = "${aws_vpc.test-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.test-igw.id}"
}

resource "aws_subnet" "test-sub" {
  vpc_id = "${aws_vpc.test-vpc.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "true"
}

resource "aws_security_group" "elb-sg" {
  name = "test-elb-sg"
  vpc_id = "${aws_vpc.test-vpc.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2-sg" {
  name = "test-ec2-sg"
  vpc_id = "${aws_vpc.test-vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "test-elb" {
  name = "test-web"
  subnets = ["${aws_subnet.test-sub.id}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]
  instances = ["${aws_instance.test-instance.id}"]
  connection_draining = "true"
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }
}

resource "aws_key_pair" "auth" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "test-instance" {
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("/root/test-key.pem")}"
    timeout = "3m"
    agent = false
  }
  instance_type = "t2.micro"
  ami = "${lookup(var.amis, var.region)}"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.ec2-sg.id}"]
  subnet_id = "${aws_subnet.test-sub.id}"
  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
    ]
  }
}
