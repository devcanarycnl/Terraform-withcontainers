# Production Load Balancer (Classic)
resource "aws_elb" "production" {
  name               = "${var.ecs_cluster_name}-elb"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port          = 80
    lb_protocol      = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout            = 3
    target             = "HTTP:8000${var.health_check_path}"
    interval           = 30
  }

  cross_zone_load_balancing = true
  idle_timeout              = 60

  tags = {
    Name = "${var.ecs_cluster_name}-elb"
  }
}



