# Access Your App - Simple Guide (Ubuntu 20)

Get your application accessible from anywhere in **5 steps**.

---

## What You Need

- Ubuntu 20 computer
- Cloudflare account (free)
- Domain on Cloudflare (free)
- Your app running on Kubernetes

---

## Step 1: Download Cloudflare Tool

Open terminal and copy-paste:

```bash
cd ~
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.tgz
tar -xzf cloudflared-linux-amd64.tgz
sudo mv cloudflared /usr/local/bin/
cloudflared version
```

**Result**: You should see version number. Done! ✓

---

## Step 2: Login to Cloudflare

```bash
cloudflared login
```

Browser opens automatically. Click "Authorize" and close when done.

**Result**: Your Cloudflare account is connected. ✓

---

## Step 3: Create Tunnel

```bash
cloudflared tunnel create myapp
```

**Keep note of the Tunnel ID shown** (looks like: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

**Result**: Tunnel created. ✓

---

## Step 4: Set Up Access

Create a simple config file:

```bash
sudo nano ~/.cloudflared/config.yml
```

Copy-paste this (change `yourdomain.com` to your real domain):

```yaml
tunnel: myapp
credentials-file: /root/.cloudflared/a1b2c3d4-e5f6-7890-abcd-ef1234567890.json

ingress:
  - hostname: app.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
```

**Save**: Press `Ctrl + X`, then `Y`, then `Enter`

**Result**: Config saved. ✓

---

## Step 5: Add DNS in Cloudflare Dashboard
1. Go to **cloudflare.com** → Login
2. Select your domain
3. Click **DNS** on left menu
4. Click **Add Record**
5. Fill in:
   - **Type**: CNAME
   - **Name**: app
   - **Content**: `a1b2c3d4-e5f6-7890-abcd-ef1234567890.cfargotunnel.com` (your Tunnel ID)
   - **Proxy status**: Orange cloud (proxied)
6. Click **Save**

Wait 30 seconds...

**Result**: DNS is set up. ✓

---

## Step 6: Start Tunnel

```bash
cloudflared tunnel run myapp
```

You should see:

```
2025-01-15T10:30:45Z INF Starting tunnel myapp
2025-01-15T10:30:46Z INF Registered tunnel connection id=0
```

**Keep this running in terminal!**

---

## Step 7: Access Your App

Open your browser and go to:

```
https://app.yourdomain.com
```

🎉 **Your app is live!**

---

## Make Tunnel Run Forever

Stop tunnel with `Ctrl + C` and run this:

```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

Now tunnel runs automatically even after restart.

Check status:

```bash
sudo systemctl status cloudflared
```

---

## Quick Troubleshooting

**App not loading?**
- Check DNS: `nslookup app.yourdomain.com` (should show Cloudflare IP)
- Make sure your app is running on `localhost:5000`

**Port wrong?**
- Find your app port: `sudo ss -tlnp | grep 5000`
- Update `config.yml` with correct port
- Restart tunnel

**Tunnel not connecting?**
- Check internet connection
- Run: `cloudflared tunnel info myapp`

---

## Done!

App is now accessible from anywhere without needing a public IP.

**That's it! 5 minutes. Simple.** ✓
