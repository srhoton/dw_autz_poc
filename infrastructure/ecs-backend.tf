resource "aws_ecs_cluster" "autz-poc" {
  name = "autz-poc"
}

resource "aws_ecs_cluster_capacity_providers" "autz-poc_provider" {
  cluster_name = aws_ecs_cluster.autz-poc.name
  capacity_providers = ["FARGATE"]
}

resource "aws_iam_role" "autz-poc_task_execution_role" {
  name = "${aws_ecs_cluster.autz-poc.name}-TaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "autz-poc-task-execution-role-policy-attachment" {
  role       = aws_iam_role.autz-poc_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "autz-poc_task_definition" {
  family = "autz-poc_task_definition"
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.autz-poc_task_execution_role.arn
  task_role_arn = aws_iam_role.autz-poc_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  container_definitions = file("${path.root}/task_definition.json")
}

resource "aws_lb" "autz-poc_lb" {
  name = "autz-poc-lb"
  internal = false
  load_balancer_type = "network"
  subnets = module.default_network.public_subnet_list

  tags = {
    Name = "autz-poc_lb"
    }
}

resource "aws_lb_target_group" "autz-poc_target_group_sdk" {
  name = "autz-poc-target-group-sdk"
  port = 3000
  protocol = "TCP"
  target_type = "ip"
  vpc_id = module.default_network.vpc_id
}

resource "aws_lb_target_group" "autz-poc_target_group_http" {
  name = "autz-poc-target-group-http"
  port = 8080
  protocol = "TCP"
  target_type = "ip"
  vpc_id = module.default_network.vpc_id
}
resource "aws_lb_listener" "autz-poc_listener_sdk" {
  load_balancer_arn = aws_lb.autz-poc_lb.arn
  port = "3000"
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.autz-poc_target_group_sdk.arn
  }
}

resource "aws_lb_listener" "autz-poc_listener_http" {
  load_balancer_arn = aws_lb.autz-poc_lb.arn
  port = "8080"
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.autz-poc_target_group_http.arn
  }
}

resource "aws_security_group" "autz-poc_ecs_service" {
  name = "autz-poc_ecs_service"
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

  ingress {
    from_port = 8080
    to_port = 8080
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
    Name = "autz-poc_ecs_service"
  }
}

resource "aws_ecs_service" "autz-poc_service" {
  name = "autz-poc-service"
  cluster = aws_ecs_cluster.autz-poc.id
  task_definition = aws_ecs_task_definition.autz-poc_task_definition.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = module.default_network.public_subnet_list
    security_groups = [aws_security_group.autz-poc_ecs_service.id]
    assign_public_ip = true
  }
      

  load_balancer {
    target_group_arn = aws_lb_target_group.autz-poc_target_group_sdk.arn
    container_name = "autz-poc_server"
    container_port = 3000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.autz-poc_target_group_http.arn
    container_name = "autz-poc_server"
    container_port = 8080
  }
}
