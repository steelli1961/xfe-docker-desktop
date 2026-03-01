# KDE Plasma Dockerfile Variant

This variant builds an Ubuntu-based Docker image with KDE Plasma as the modern desktop environment, offering a feature-rich interface with productivity tools, multiple browsers, and development capabilities.

**Important**: Safari is not available on Linux. Epiphany (GNOME Web) is included as the closest WebKit-based alternative. If you need macOS Safari specifically, run macOS or use a remote macOS service.

---

## Overview

**Desktop Environment**: KDE Plasma 5
- Modern, fully-featured desktop with customizable widgets
- Application launcher with search capabilities
- System tray and taskbar
- Multiple virtual desktops support
- Configuration through KDE System Settings

**Architecture**:
- Base OS: Ubuntu 22.04 LTS
- Display Server: X11 via Xorg
- Remote Access: XRDP protocol on port 3389
- Session Management: supervisord (multiple services in one container)
- Default User: `kdeuser` with password `password`

---

## Included Applications

### Browsers
- **Google Chrome** (amd64 architecture)
- **Chromium** (non-amd64 architectures, as fallback)
- **Firefox** (automatic architecture detection)
- **Epiphany** (GNOME/WebKit-based browser for Safari-like experience)

### Development Tools
- **code-server**: Web-based VS Code on `http://localhost:8080`

*(VNC has been removed from this build; RDP only.)*
- **Terminal**: KDE Konsole
- **Text Editors**: Various KDE applications

### System Tools
- **File Manager**: Dolphin (KDE file manager)
- **SSH**: OpenSSH server for remote command access
- **Samba**: File sharing protocol
- **PulseAudio**: Sound server
- **Network Manager**: Network configuration

### Core KDE Components
- `kde-plasma-desktop`: Core Plasma desktop
- `plasma-desktop`: Plasma shell and components
- `kde-baseapps`: Essential KDE applications
- `policykit-1` & `policykit-1-gnome`: Authorization framework (required for KDE)
- D-Bus: System/session message bus

---

## Building

### Standard Build

```bash
docker build -f dockerfile-kde-variant -t xfe-kde:latest .
```

### Κατασκευή (Ελληνικά)

```bash
docker build -f dockerfile-kde-variant -t xfe-kde:latest .
```

(Η εντολή είναι ίδια στα Αγγλικά και στα Ελληνικά – απλώς έχουμε περιγράψει το βήμα για Ελληνόφωνους χρήστες)

### Build with Custom Tag

```bash
docker build -f dockerfile-kde-variant -t xfe-kde:v1.0 .
```

### Κατασκευή με προσαρμοσμένη ετικέτα (Ελληνικά)

```bash
docker build -f dockerfile-kde-variant -t xfe-kde:v1.0 .
```

### Build with Progress Output

```bash
docker build --progress=plain -f dockerfile-kde-variant -t xfe-kde:latest .
```

### Κατασκευή με εμφάνιση προόδου (Ελληνικά)

```bash
docker build --progress=plain -f dockerfile-kde-variant -t xfe-kde:latest .
```

### Build-Time Variables

The Dockerfile includes architecture detection:
- **amd64/x86_64**: Installs Google Chrome
- **arm64/aarch64**: Installs Chromium (Chrome not available)
- **Other architectures**: Installs Chromium

Firefox is automatically downloaded for the detected architecture.

**Build Duration**: 10-20 minutes depending on hardware and network speed.

---

## Running

### Basic Run

```bash
docker run -d --name xfe-kde -p 3389:3389 xfe-kde:latest
```

### Βασική Εκτέλεση (Ελληνικά)

```bash
docker run -d --name xfe-kde -p 3389:3389 xfe-kde:latest
```
### Run with All Ports Exposed

```bash
docker run -d \
  --name xfe-kde \
  -p 3389:3389 \
  -p 8080:8080 \
  -p 22:2222 \
  xfe-kde:latest
```

### Run with Volume Mounts (Persistent Data)

```bash
docker run -d \
  --name xfe-kde \
  -p 3389:3389 \
  -v $HOME/xfe-data:/home/kdeuser/data \
  -v $HOME/xfe-config:/home/kdeuser/.config \
  xfe-kde:latest
```

### Run with GPU Acceleration

```bash
docker run -d \
  --name xfe-kde \
  -p 3389:3389 \
  --device /dev/dri \
  xfe-kde:latest
```

### Run with Custom Memory Limit

```bash
docker run -d \
  --name xfe-kde \
  -p 3389:3389 \
  -m 2gb \
  xfe-kde:latest
```

### Run with Environment Variables

```bash
docker run -d \
  --name xfe-kde \
  -p 3389:3389 \
  -e LANG=de_DE.UTF-8 \
  -e TZ=Europe/Berlin \
  xfe-kde:latest
```

### Εκτέλεση με μεταβλητές περιβάλλοντος (Ελληνικά)

```bash
docker run -d \
  --name xfe-kde \
  -p 3389:3389 \
  -e LANG=de_DE.UTF-8 \
  -e TZ=Europe/Berlin \
  xfe-kde:latest
```

Όλες οι παραπάνω παραλλαγές εκτέλεσης λειτουργούν με τον ίδιο τρόπο και μπορείτε να τις χρησιμοποιήσετε και στα Ελληνικά με τον ίδιο ακριβώς κώδικα. Απλά αντικαταστήστε τις παραμέτρους (όπως tags, ports, volumes) ανάλογα με τις ανάγκες σας.

---

## Connecting

### RDP Connection

**Local Clients**:
- **Windows**: Remote Desktop Connection (`mstsc.exe`)
- **macOS**: Microsoft Remote Desktop (from App Store)
- **Linux**: Remmina, xfreerdp, or other RDP clients

**Connection Details**:
- Host: `localhost` or `127.0.0.1`
- Port: `3389` (or mapped port from `docker run`)
- Username: `kdeuser`
- Password: `password`
- Color Depth: 24-bit (recommended)
- Resolution: 1920x1080 (configurable)

### Code-Server Access

**Via Browser**:
```
http://localhost:8080
```

**Default Password**: `password`

Any browser on your host machine can access code-server to edit files directly in VS Code.

### SSH Access

```bash
# If mapped to port 2222: 
ssh -p 2222 kdeuser@localhost

# Or port 22 if exposed:
ssh kdeuser@localhost
```

### XDMCP Connection (Linux/macOS)

XDMCP (X Display Management Control Protocol) provides native X11 remote display access.

**From Linux**:

```bash
# 1. Start X server display on your machine (if needed)
Xvfb :99 -screen 0 1920x1080x24 &

# 2. Connect to container via XDMCP
X -query localhost -broadcast :99

# Or use xdmcp client:
xdmcp -host localhost &
```

**From macOS**:

1. Install XQuartz if not already installed:
   ```bash
   brew install xquartz
   ```

2. Start X11 session:
   ```bash
   open -a XQuartz
   # In XQuartz terminal:
   X -query localhost :0
   ```

3. Or use the XDarwin graphical launcher:
   - Open XQuartz → Applications → Utilities → X11 Launcher
   - Set Query Host: `localhost`
   - Click "Open"

**Port Mapping Required**:
```bash
docker run -d \
  --name xfe-kde \
  -p 3389:3389 \   # RDP
  -p 177:177/udp \ # XDMCP
  -p 2222:22 \     # SSH
  xfe-kde:latest
```

**Connection Details**:
- Host: `localhost`
- Port: `177` (XDMCP, UDP)
- All logins default to: `kdeuser` / `password`

---

## Network and Port Mapping

| Service | Internal Port | Default Map | Purpose |
|---------|---------------|-------------|---------|
| XRDP | 3389 | 3389 | Remote desktop protocol || XDMCP | 177 | 177/udp | X11 remote display (Linux/macOS) || SSH | 22 | 22 or 2222 | Remote command shell |
| code-server | 8080 | 8080 | Web-based VS Code |
| DNSmasq (optional) | 53 | N/A | DNS (if added) |

---

## Configuration

### Supervisor Services

The container runs multiple services via supervisord. Configuration location: `/etc/supervisor/supervisord.conf`

**Services**:
- `dbus` - Message bus (priority 1, starts first)
- `sshd` - SSH server (priority 2)
- `xrdp-sesman` - XRDP session manager (priority 3)
- `xrdp` - XRDP server (priority 4)
- `code-server` - VS Code server (priority 5)

**View Service Status**:
```bash
docker exec xfe-kde supervisorctl status
```

**Restart a Service**:
```bash
docker exec xfe-kde supervisorctl restart xrdp
```

### X Server Configuration

Display resolution is set in `/etc/X11/xrdp/xorg.conf`:
- Default: 1920x1080 at 24-bit color depth
- Monitor refresh: 48-75 Hz horizontal 28-80 kHz

### Xsession Configuration

KDE Plasma is started via `/home/kdeuser/.xsession` with `startplasma-x11` command.

---

## System Information

### Default User

**Username**: `kdeuser`
**Password**: `password`
**UID/GID**: 1000
**Home Directory**: `/home/kdeuser`
**Shell**: `/bin/bash`
**Groups**: `sudo`

### System Users

- `remoteuser`: Alternative SSH user (password: `password`)
- `root`: System administrator

### File Locations

- **Samba Shares**: `/home/kdeuser/share/samba`
- **X11 Config**: `/etc/X11/xrdp/xorg.conf`
- **XRDP Config**: `/etc/xrdp/xrdp.ini`, `/etc/xrdp/startwm.sh`
- **SSH Config**: `/etc/ssh/sshd_config`
- **Supervisor Config**: `/etc/supervisor/supervisord.conf`

---

## Persistence

By default, changes inside the container are lost when it stops. To persist data:

### Volume Mounts

```bash
docker run -d \
  -v $HOME/my-desktop:/home/kdeuser \
  xfe-kde:latest
```

### Commit Container to New Image

```bash
docker commit xfe-kde xfe-kde:custom
```

### Use Docker Named Volumes

```bash
docker volume create kde-data
docker run -d \
  -v kde-data:/home/kdeuser \
  xfe-kde:latest
```

---

## Troubleshooting

### Black Screen on RDP Connect

**Causes & Solutions**:

1. **KDE Plasma not starting**:
   ```bash
   docker logs xfe-kde
   docker exec xfe-kde tail -50 /var/log/xrdp/xrdp.log
   ```

2. **Missing PolicyKit**:
   - Verify `policykit-1` is installed
   - Check: `docker exec xfe-kde dpkg -l | grep policy`

3. **D-Bus issues**:
   ```bash
   docker exec xfe-kde dbus-daemon --system --nofork
   ```

4. **X Server not running**:
   ```bash
   docker exec xfe-kde ps aux | grep -i x
   ```

### Cannot Connect to RDP

1. **Check container running**:
   ```bash
   docker ps | grep xfe-kde
   ```

2. **Verify port mapping**:
   ```bash
   docker port xfe-kde
   ```

3. **Test port connectivity**:
   ```bash
   nc -zv localhost 3389
   ```

4. **Check XRDP service**:
   ```bash
   docker exec xfe-kde supervisorctl status xrdp
   ```

### Slow Performance

1. **Increase allocated memory**:
   ```bash
   docker run -d -m 2gb xfe-kde:latest
   ```

2. **Enable GPU acceleration**:
   ```bash
   docker run -d --device /dev/dri xfe-kde:latest
   ```

3. **Check CPU usage**:
   ```bash
   docker stats xfe-kde
   ```

### Applications Not Starting

1. **Check X display**:
   ```bash
   docker exec xfe-kde echo $DISPLAY
   ```

2. **Verify library availability**:
   ```bash
   docker exec xfe-kde ldconfig -p | grep libX11
   ```

### Code-Server Not Accessible

1. **Check it's running**:
   ```bash
   docker exec xfe-kde supervisorctl status code-server
   ```

2. **View logs**:
   ```bash
   docker logs xfe-kde | grep code-server
   ```

3. **Test port**:
   ```bash
   curl http://localhost:8080
   ```

---

## Security Notes

⚠️ **Warning**: This configuration uses default credentials and is NOT suitable for production or untrusted networks.

### Before Production Use

1. **Change Passwords**:
   - Modify `RUN echo "kdeuser:password"` in Dockerfile
   - Or set via: `docker exec xfe-kde passwd kdeuser`

2. **Disable SSH Password Auth**:
   ```bash
   docker exec xfe-kde sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   ```

3. **Use SSH Keys**:
   ```bash
   docker run -v /path/to/authorized_keys:/home/kdeuser/.ssh/authorized_keys xfe-kde
   ```

4. **Network Isolation**:
   - Don't expose ports to untrusted networks
   - Use firewall rules to limit access
   - Run on private networks only

5. **Remove Unnecessary Services**:
   - Disable SSH if not needed: Comment out `sshd` in supervisord config
   - Disable code-server if not used

6. **Use Read-Only Filesystem** (where possible):
   ```bash
   docker run --read-only xfe-kde:latest
   ```

7. **Run as Non-Root**:
   - Container already runs most services as appropriate users
   - Verify with: `docker exec xfe-kde ps aux`

---

## Performance Tips

### Resource Recommendations

- **Minimum**: 512 MB RAM, 1 CPU
- **Recommended**: 1-2 GB RAM, 2+ CPUs
- **Optimal**: 4+ GB RAM, 4+ CPUs

### Optimization

1. **Use SSD storage** for container runtime
2. **Enable GPU acceleration** if available: `--device /dev/dri`
3. **Pre-build images** to avoid build delays
4. **Use smaller terminal fonts** in RDP clients to reduce bandwidth
5. **Reduce color depth** if network is limited (16-bit instead of 24-bit)
6. **Mount volumes** on fast NFS/SMB shares rather than embedded

### Bandwidth Optimization

- Use RDP client compression options
- Reduce screen resolution if bandwidth is limited
- Disable wallpaper/effects in KDE settings
- Compress SSH connections: `ssh -C`

---

## Customizations

### Build a Custom Image

1. **Modify Dockerfile**:
   ```dockerfile
   FROM xfe-kde:latest
   
   # Add your customizations
   RUN apt-get update && apt-get install -y custom-package
   RUN bash -c 'echo "custom config" > /home/kdeuser/.custom'
   ```

2. **Build**:
   ```bash
   docker build -f Dockerfile.custom -t xfe-kde:custom .
   ```

### Add Additional Packages

```bash
docker run -it xfe-kde:latest bash
apt-get update
apt-get install desired-package
exit
docker commit <container_id> xfe-kde:with-package
```

### Pre-install VS Code Extensions

Modify `/etc/supervisor/supervisord.conf` code-server command:
```ini
command=/usr/bin/code-server --bind-addr 0.0.0.0:8080 --install-extension <extension-id>
```

---

## Container Lifecycle

```bash
# View container
docker ps -a | grep xfe-kde

# Stop container
docker stop xfe-kde

# Start container
docker start xfe-kde

# Restart container
docker restart xfe-kde

# Remove container
docker rm xfe-kde

# View logs
docker logs -f xfe-kde

# Execute command
docker exec -it xfe-kde bash

# Inspect container
docker inspect xfe-kde
```

---

## Related Resources

- [KDE Plasma Documentation](https://docs.kde.org/)
- [XRDP Project](https://github.com/neutrinolabs/xrdp)
- [Docker Documentation](https://docs.docker.com/)
- [Ubuntu 22.04 LTS](https://releases.ubuntu.com/jammy/)
- [code-server Documentation](https://github.com/coder/code-server)
- [X11 Forwarding](https://www.x.org/)

---

## License & Attribution

- **KDE Plasma**: LGPL v2+
- **Ubuntu**: Canonical proprietary with open-source components
- **XRDP**: Apache 2.0
- **Firefox**: Mozilla Public License
- **Chrome**: Multiple licenses
- This Dockerfile: MIT or as specified in project LICENSE

---

## Support & Issues

For issues or questions:

1. Check container logs: `docker logs xfe-kde`
2. Review troubleshooting section above
3. Verify all ports are accessible
4. Test with a simpler RDP client first
5. Check system resources (`docker stats`)
6. Rebuild image: `docker build --no-cache ...`
