KDE Dockerfile Variant
======================

This variant builds an Ubuntu-based image with KDE Plasma as the desktop environment, Google Chrome, Visual Studio Code (desktop), and Epiphany (GNOME Web) as a Safari-like WebKit browser alternative.

Important: Safari is not available on Linux. Epiphany (GNOME Web) is included as the closest WebKit-based alternative. If you need macOS Safari specifically, run macOS or use a remote macOS service.

Build

```bash
docker build -f dockerfile-kde-variant -t xfe-kde:latest .
```

Run

Expose XRDP port and start the container:

```bash
docker run -d --name xfe-kde -p 3389:3389 xfe-kde:latest
```

Connect

- Use any RDP client (Windows Remote Desktop, Remmina, Microsoft Remote Desktop for macOS) and connect to `localhost:3389`.
- Login with user `kdeuser` and password `password` (change this in a production setup).

Notes

- Chrome and VS Code are installed inside the image and should be available from the KDE application launcher.
- For persistent data, mount volumes for `/home/kdeuser` and other service directories.
- This image exposes XRDP on port 3389 and runs `sshd`, `dbus`, and `xrdp` via `supervisord`.
- Replace default passwords before using on untrusted networks.
