# Homelab — Map of Content

## Infrastructure
| Machine | IP | Rôle | OS |
|---|---|---|---|
| proxmox | 192.168.1.10 | Hyperviseur | Proxmox VE |
| nas | 192.168.1.20 | Stockage | TrueNAS |
| docker01 | 192.168.1.30 | Conteneurs | Ubuntu/NixOS |

## Services
- [[Runbook Grafana]]
- [[Runbook Portainer]]
- [[Runbook Uptime Kuma]]
- [[Runbook Vaultwarden]]

## Réseau
- LAN : 192.168.1.0/24
- Tailscale : 100.x.x.x
- DNS : AdGuard DNS-over-TLS

## ADRs
- [[ADR — Choix NixOS pour le laptop]]
- [[ADR — Tailscale vs WireGuard]]

---
Tags: #moc #homelab
