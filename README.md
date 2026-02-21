# XFE Docker Desktop

This project provides containerized desktop environments using Docker and XRDP for remote desktop access. It includes XFCE4 (default) and KDE Plasma (variant) desktop environments.

## Project Structure

```
xfe-docker-desktop/
├── dockerfile-kde              # XFCE4-based desktop environment (default)
├── dockerfile-kde-variant      # KDE Plasma desktop environment
├── README.md                   # This file
├── README-kde-variant.md       # KDE variant-specific documentation
└── scripts/
    ├── rebuild-on-change.sh    # Automatic Docker image rebuilding on Dockerfile changes
    ├── run-cde.sh              # Build and run CDE (Common Desktop Environment)
    └── run-hpux.sh             # Run HP-UX virtual machine in QEMU
```

---

## Dockerfiles

### dockerfile-kde (XFCE4 Default)

**Purpose**: Builds an Ubuntu-based image with XFCE4 desktop environment, SSH, Samba file sharing, and XRDP remote desktop access.

**Included Components**:
- Desktop: XFCE4 with terminal
- Remote Access: XRDP on port 3389
- File Sharing: Samba server
- SSH: OpenSSH server (`sshd`)
- Audio: PulseAudio
- Additional Tools: nano, fonts, X11 utilities
- User: `kdeuser` (password: `password`)

**Build**:
```bash
docker build -t xfe-kde:latest -f dockerfile-kde .
```

**Run**:
```bash
docker run -d --name xfe-kde -p 3389:3389 xfe-kde:latest
```

**Connect**: Use any RDP client and connect to `localhost:3389` with credentials `kdeuser:password`

**Notes**:
- XFCE4 is lightweight and fast
- Suitable for systems with lower resources
- Default display resolution: 1920x1080
- Change default passwords before production use

---

### dockerfile-kde-variant (KDE Plasma)

**Purpose**: Builds an Ubuntu-based image with KDE Plasma desktop environment, providing a modern, feature-rich desktop with multiple browsers and development tools.

**Included Components**:
- Desktop: KDE Plasma (modern KDE environment)
- Remote Access: XRDP on port 3389
- Browsers: Google Chrome, Firefox, Epiphany (WebKit-based)
- Development: code-server (web-based VS Code) on port 8080
- File Sharing: Samba server
- SSH: OpenSSH server (`sshd`)
- Audio: PulseAudio
- System Services: D-Bus, PolicyKit (for KDE functionality)
- User: `kdeuser` (password: `password`)

**Build**:
```bash
docker build -t xfe-kde:latest -f dockerfile-kde-variant .
```

**Run**:
```bash
docker run -d --name xfe-kde -p 3389:3389 xfe-kde:latest
```

**Access Services**:
- **RDP Desktop**: `localhost:3389` (use RDP client)
- **Code-server**: `http://localhost:8080` (browser-based VS Code)
- **User**: `kdeuser` / Password: `password`

**Notes**:
- More feature-rich than XFCE4, requires more resources
- Includes Chrome, Firefox, and Epiphany browsers
- PolicyKit and D-Bus ensure proper KDE functionality
- Change default passwords before production use
- See [README-kde-variant.md](README-kde-variant.md) for detailed KDE information

---

## Scripts

### scripts/rebuild-on-change.sh

**Purpose**: Automatically rebuilds Docker image when Dockerfile changes, storing build hash to detect modifications.

**Usage**:
```bash
./scripts/rebuild-on-change.sh [OPTIONS] [context]
```

**Options**:
- `-f` : Force rebuild regardless of changes
- `-i <image_name>` : Specify image name (default: `xfe-kde-variant`)
- `-t <tag>` : Specify image tag (default: `latest`)
- `-d <dockerfile>` : Specify Dockerfile path (default: `dockerfile-kde-variant`)
- `-c <context>` : Specify build context (default: current directory `.`)

**Examples**:
```bash
# Rebuild if dockerfile-kde-variant changed
./scripts/rebuild-on-change.sh

# Force rebuild
./scripts/rebuild-on-change.sh -f

# Build specific Dockerfile
./scripts/rebuild-on-change.sh -d dockerfile-kde -i xfe-xfce4 -t latest

# Rebuild with custom context
./scripts/rebuild-on-change.sh -c /path/to/context
```

**How It Works**:
1. Computes SHA256 hash of the Dockerfile
2. Compares with previously stored hash in `.build_hashes/`
3. Rebuilds image if hash differs or `-f` flag is used
4. Updates stored hash on successful build
5. Skips rebuild if no changes detected

**Benefits**:
- Prevents unnecessary rebuilds
- Useful in CI/CD pipelines
- Detects and responds to Dockerfile modifications automatically

---

### scripts/run-cde.sh

**Purpose**: Builds and runs CDE (Common Desktop Environment) inside a Docker container with X11 forwarding from the host.

**Usage**:
```bash
./scripts/run-cde.sh [OPTIONS]
```

**Options**:
- `--repo <git_repo_url>` : Git repository URL for CDE source (default: `https://github.com/ibara/cde.git`)
- `--tag <branch-or-tag>` : Git branch or tag to clone (default: `main`)
- `--image <image_name>` : Docker image name (default: `cde-builder:latest`)
- `--display <DISPLAY>` : X11 display to forward (default: `:0`)
- `-h, --help` : Show help message

**Examples**:
```bash
# Build and run CDE with default settings
./scripts/run-cde.sh

# Use specific Git branch
./scripts/run-cde.sh --tag v1.0

# Custom display forwarding
./scripts/run-cde.sh --display :1

# Custom repository
./scripts/run-cde.sh --repo https://github.com/alternative/cde.git
```

**How It Works**:
1. Creates temporary build context with Ubuntu 22.04 base
2. Installs build tools (autotools, cmake, libX11 dev libraries)
3. Builds Docker image for CDE compilation
4. Runs container with:
   - Git clone of CDE repository
   - Build attempt using `autogen.sh` and `configure`
   - X11 socket mounting for graphics display
   - GPU device access for hardware acceleration
5. Launches CDE with `startcde` if build succeeds
6. Drops to bash shell for debugging if build fails
7. Cleans up temporary build context

**Requirements**:
- X11 display server running on host
- Xauthority configured for local connections
- Docker and Git installed
- Sufficient disk space (~2GB) for build and compilation

**Notes**:
- CDE is a legacy desktop environment; compile time varies
- Build may take 10-30 minutes depending on system
- X11 forwarding requires proper `DISPLAY` and `XAUTHORITY` setup
- If build fails, container drops to shell for manual debugging
- User responsibility to provide/obtain CDE source code

---

### scripts/run-hpux.sh

**Purpose**: Runs an HP-UX virtual machine in QEMU emulator.

**Usage**:
```bash
./scripts/run-hpux.sh -i <image_path> [OPTIONS]
```

**Required Arguments**:
- `-i <image_path>` : Path to HP-UX disk image or ISO file (REQUIRED)

**Optional Arguments**:
- `-a <architecture>` : CPU architecture: `hppa` or `ia64` (default: `hppa`)
- `-m <memory_mb>` : Memory in MB (default: `1024`)
- `-n <name>` : VM name for logging/identification (default: `hpux-vm`)
- `-h` : Show help message

**Examples**:
```bash
# Run HP-UX HPPA VM with default settings
./scripts/run-hpux.sh -i /path/to/hpux-11i-v3.img

# Run with more memory
./scripts/run-hpux.sh -i /path/to/hpux.img -m 2048

# Run Itanium (IA64) architecture
./scripts/run-hpux.sh -i /path/to/itanium.iso -a ia64

# Name VM for monitoring
./scripts/run-hpux.sh -i /path/to/hpux.img -n mylab-hpux
```

**How It Works**:
1. Validates image file exists
2. Detects appropriate QEMU binary:
   - `qemu-system-hppa` for PA-RISC (32/64-bit)
   - `qemu-system-ia64` for Itanium
3. Configures appropriate machine settings:
   - HPPA uses IDE interface (more compatible)
   - IA64 uses IDE with graphics display
4. Allocates specified memory to VM
5. Launches VM with serial console (`mon:stdio`)

**Requirements**:
- QEMU installed with desired architecture support:
  - `qemu-system-hppa` for PA-RISC
  - `qemu-system-ia64` for Itanium
- HP-UX disk image or ISO file (user must obtain)
- Appropriate HP-UX license (user responsibility)

**Installation of QEMU targets**:
```bash
# macOS with Homebrew
brew install qemu

# Ubuntu/Debian
sudo apt-get install qemu-system-misc qemu-system-x86 qemu-system-ppc

# Arch
sudo pacman -S qemu-full
```

**Notes**:
- QEMU emulation of HP-UX can be slow
- HPPA and IA64 support in QEMU is limited
- Device compatibility varies by emulated architecture
- Serial console is primary interface (VGA on IA64 if available)
- User must provide/license HP-UX installation media
- VM runs in foreground; use `&` to background or tmux/screen

---

## Quick Start

### Option 1: XFCE4 (Lightweight)
```bash
docker build -t xfe-xfce4 -f dockerfile-kde .
docker run -d --name xfe-xfce4 -p 3389:3389 xfe-xfce4
# Connect to localhost:3389 with RDP client
```

### Option 2: KDE Plasma (Feature-Rich)
```bash
docker build -t xfe-kde -f dockerfile-kde-variant .
docker run -d --name xfe-kde -p 3389:3389 -p 8080:8080 xfe-kde
# Connect to localhost:3389 for RDP, or localhost:8080 for code-server
```

### Option 3: Automatic Rebuild on Changes
```bash
./scripts/rebuild-on-change.sh -f  # Force first build
./scripts/rebuild-on-change.sh  # Subsequent calls only rebuild if Dockerfile changed
```

---

## Security Considerations

⚠️ **Important**: The default configuration uses simple credentials and should NOT be used in untrusted environments.

**Before Production Use**:
1. Change default passwords (currently `kdeuser:password`)
2. Disable SSH password authentication; use key-based auth
3. Run containers with restricted network access
4. Use environment-specific credentials
5. Scan images for vulnerabilities
6. Mount volumes with appropriate permissions
7. Run containers with minimal privileges
8. Consider using `--read-only` or read-only root filesystem

---

## Troubleshooting

### Black Screen on RDP Connect
- Check container logs: `docker logs <container_name>`
- Ensure XRDP service is running: `docker exec <container_name> ps aux | grep xrdp`
- Verify port forwarding: `docker port <container_name>`
- Try reconnecting or restarting container

### No Display Manager
- Verify X11 packages are installed in Dockerfile
- Check `.xsession` file exists in home directory
- Review supervisor service logs

### File Share Not Working
- Verify Samba service: `docker exec <container_name> smbstatus`
- Check Samba configuration: `/etc/samba/smb.conf`
- Ensure proper permissions on shared directories

### X11 Forwarding Issues (run-cde.sh)
- Verify `DISPLAY` environment variable: `echo $DISPLAY`
- Check X11 socket: `ls -la /tmp/.X11-unix/`
- Allow local connections: `xhost +local:`
- Export Xauthority: `touch /tmp/.docker.xauth && xauth -f /tmp/.docker.xauth nlist "$DISPLAY" | sed 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -`

---

## Container Management

```bash
# View running containers
docker ps

# Stop container
docker stop <container_name>

# Start stopped container
docker start <container_name>

# Remove container
docker rm <container_name>

# View logs
docker logs -f <container_name>

# Execute command in container
docker exec -it <container_name> bash

# Mount volumes for persistent data
docker run -d -v /path/host:/home/kdeuser/shared <image>
```

---

## Performance Tips

- **XFCE4** (dockerfile-kde): Lighter resource usage ~512MB RAM
- **KDE Plasma** (dockerfile-kde-variant): Richer features ~1GB+ RAM
- Use GPU acceleration: `--device /dev/dri` (if available)
- Increase memory for complex applications: `-m 2gb`
- Use SSD for faster container startup
- Pre-build images to avoid build time on first run

---

## Related Resources

- [Docker Documentation](https://docs.docker.com/)
- [XRDP Home](https://github.com/neutrinolabs/xrdp)
- [XFCE4 Project](https://www.xfce.org/)
- [KDE Plasma Project](https://kde.org/plasma-desktop/)
- [QEMU Documentation](https://www.qemu.org/)
- [Common Desktop Environment (CDE)](http://cde.org/)
