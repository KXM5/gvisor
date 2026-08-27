terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "explore" {
  triggers = { always = uuid() }
  provisioner "local-exec" {
    command = <<EOT
      echo "Stack ID: $SPACELIFT_STACK_ID"
      echo "Run ID: $SPACELIFT_RUN_ID"
      echo "Account: $SPACELIFT_ACCOUNT"
      echo "Space: $SPACELIFT_SPACE"
      env | grep SPACELIFT_
    EOT
  }
}
