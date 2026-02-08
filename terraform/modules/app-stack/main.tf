# App Stack Module
#
# A minimal but production-ready module demonstrating:
# - Security group configuration
# - EC2 instance deployment
# - User data for initial configuration
# - Proper tagging and naming

# Security group for the application instance
resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  description = "Security group for ${var.project_name} application in ${var.environment}"

  # Allow SSH from specified CIDR (restrict this in production)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Allow HTTP traffic (for demo web application)
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 instance for the application
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app.id]

  monitoring = var.enable_monitoring

  # User data script to set up a simple web server
  # This proves the instance is deployed and accessible
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              # Create a simple status page
              cat > /var/www/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>CI/CD Pipeline Demo</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          max-width: 800px;
                          margin: 50px auto;
                          padding: 20px;
                          background-color: #f5f5f5;
                      }
                      .container {
                          background-color: white;
                          padding: 30px;
                          border-radius: 8px;
                          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                      }
                      h1 { color: #2c3e50; }
                      .status { color: #27ae60; font-weight: bold; }
                      .info { margin: 20px 0; padding: 15px; background-color: #ecf0f1; border-radius: 4px; }
                      code { background-color: #34495e; color: #ecf0f1; padding: 2px 6px; border-radius: 3px; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🚀 CI/CD Pipeline Demo</h1>
                      <p class="status">✅ Instance deployed successfully via GitHub Actions!</p>

                      <div class="info">
                          <h2>Deployment Information</h2>
                          <p><strong>Project:</strong> ${var.project_name}</p>
                          <p><strong>Environment:</strong> ${var.environment}</p>
                          <p><strong>Instance Type:</strong> ${var.instance_type}</p>
                          <p><strong>Deployed by:</strong> Terraform + GitHub Actions</p>
                      </div>

                      <h2>What This Demonstrates</h2>
                      <ul>
                          <li>Automated infrastructure deployment via CI/CD</li>
                          <li>Terraform modules and composition</li>
                          <li>Security group configuration</li>
                          <li>User data script execution</li>
                          <li>Production-grade pipeline practices</li>
                      </ul>

                      <h2>Repository</h2>
                      <p>Check out the full pipeline at: <code>github.com/justin-henson/au-nz-cicd-pipeline</code></p>
                  </div>
              </body>
              </html>
              HTML
              EOF

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app"
    }
  )

  # Prevent accidental instance replacement
  lifecycle {
    ignore_changes = [
      # User data changes don't require instance replacement
      # If you need to update user data, use configuration management tools
      user_data
    ]
  }
}
