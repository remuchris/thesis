# Demonstration von PID Namespaces und cgroups in Docker

In diesem Repository dokumentiere ich zwei zentrale Mechanismen zur Isolierung von Containern: **PID-Namespaces** und **cgroups**. Ziel ist es, diese Konzepte verständlich zu machen und mit praktischen Beispielen und Screenshots nachvollziehbar darzustellen.

---

## 🧩 PID Namespace – Prozessisolation zwischen Containern

### Was bewirkt der PID-Namespace?

Ein PID-Namespace sorgt dafür, dass ein Container nur die Prozesse sieht, die innerhalb dieses Namespaces gestartet wurden. Aus Sicht des Containers beginnt der Prozessbaum immer bei PID 1.

### Beispiel: Drei Container starten und vergleichen

```bash
# Container starten
docker run -dit --name c1 ubuntu bash
docker run -dit --name c2 ubuntu bash
docker run -dit --name c3 ubuntu bash

# ps-Befehl installieren (falls nötig)
docker exec c1 apt update ; docker exec c1 apt install -y procps
docker exec c2 apt update ; docker exec c2 apt install -y procps
docker exec c3 apt update ; docker exec c3 apt install -y procps

# Prozesslisten abrufen
docker exec c1 ps -ef
docker exec c2 ps -ef
docker exec c3 ps -ef

# Prozesse aus Host-Sicht
docker top c1
docker top c2
docker top c3
```

🖼️ **Visualisierung:** Jeder Container sieht nur `bash` und `ps`, Host sieht alle.

---

## ⚙️ cgroups – Ressourcenbegrenzung

### 🧠 Konzept

**cgroups (control groups)** ermöglichen es, Ressourcen wie CPU und Speicher für Container zu begrenzen. Jeder Container erhält eine eigene cgroup mit Limits.

### 🧪 Container mit Limits starten

```bash
docker run -dit --name c1 --memory=256m --cpus="0.5" ubuntu bash
docker run -dit --name c2 --memory=128m --cpus="1.0" ubuntu bash
docker run -dit --name c3 --memory=512m --cpus="2.0" ubuntu bash
```

### 🧾 Limits prüfen (Linux-Host / WSL2)

```bash
# Container-ID holen
docker inspect -f '{{.Id}}' c1

# Limits prüfen (cgroup v2 Beispiel)
cat /sys/fs/cgroup/docker/<CONTAINER_ID>/memory.max
cat /sys/fs/cgroup/docker/<CONTAINER_ID>/cpu.max
```

### 📊 Live-Ressourcennutzung

```bash
docker stats c1 c2 c3
```

---

## 🛠 Automatisiertes Skript

```bash
# cgroup_check.sh
#!/bin/bash
containers=("c1" "c2" "c3")
docker run -dit --name c1 --memory=256m --cpus="0.5" ubuntu bash
docker run -dit --name c2 --memory=128m --cpus="1.0" ubuntu bash
docker run -dit --name c3 --memory=512m --cpus="2.0" ubuntu bash

echo ""
echo "╔════════════╦════════════════╦═══════════════════════╗"
echo "║ Container  ║ Memory Limit   ║ CPU Limit             ║"
echo "╠════════════╬════════════════╬═══════════════════════╣"

for cname in "${containers[@]}"; do
    cid=$(docker inspect --format '{{.Id}}' "$cname")
    cgroup_path="/sys/fs/cgroup/docker/$cid"
    [ ! -d "$cgroup_path" ] && cgroup_path="/sys/fs/cgroup/$cid"

    mem=$(cat "$cgroup_path/memory.max" 2>/dev/null || echo "n/a")
    cpu=$(cat "$cgroup_path/cpu.max" 2>/dev/null || echo "n/a")

    if [[ $mem =~ ^[0-9]+$ ]]; then
        mem_mb=$(($mem / 1024 / 1024))
        mem_text="${mem_mb} MB"
    else
        mem_text="$mem"
    fi

    echo "║ $(printf '%-10s' $cname) ║ $(printf '%-14s' "$mem_text") ║ $(printf '%-21s' "$cpu") ║"
done

echo "╚════════════╩════════════════╩═══════════════════════╝"
```

---

## 📂 Screenshots & Visualisierungen

Die dazugehörigen Visualisierungen findest du im Ordner `/images`:

- `pid_namespace_isolation.svg`
- `cgroup_limits.svg`

---

## 📘 Quelle

Erstellt für die Masterarbeit zum Thema Containertechnologie – Demonstration von Sicherheits- und Isolationsmechanismen.