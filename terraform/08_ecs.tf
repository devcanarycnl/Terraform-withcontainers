resource "aws_ecs_cluster" "production" {
  name = "${var.ecs_cluster_name}-cluster"
}

resource "aws_launch_template" "ecs" {
  name                = "${var.ecs_cluster_name}-cluster"
  image_id            = lookup(var.amis, var.region)
  instance_type       = var.instance_type
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  key_name = aws_key_pair.production.key_name
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.ecs.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER='${var.ecs_cluster_name}-cluster' > /etc/ecs/ecs.config
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "app" {
  template = file("templates/django_app.json.tpl")

  vars = {
    docker_image_url_django = var.docker_image_url_django
    region                  = var.region
  }
}

resource "aws_ecs_task_definition" "app" {
  family                = "django-app"
  container_definitions = data.template_file.app.rendered
}

resource "aws_ecs_service" "production" {
  name            = "${var.ecs_cluster_name}-service"
  cluster         = aws_ecs_cluster.production.id
  task_definition = aws_ecs_task_definition.app.arn
  iam_role        = aws_iam_role.ecs-service-role.arn
  desired_count   = var.app_count
  depends_on      = [aws_elb.production, aws_iam_role_policy.ecs-service-role-policy]

  load_balancer {
    elb_name       = aws_elb.production.name
    container_name = "django-app"
    container_port = 8000
  }
}