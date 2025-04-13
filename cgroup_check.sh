#!/bin/bash

# Container-Namen
containers=("c1" "c2" "c3")

# Container mit Limits starten
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

    # Fallback für WSL2 oder andere Pfade
    if [ ! -d "$cgroup_path" ]; then
        cgroup_path="/sys/fs/cgroup/$cid"
    fi

    mem=$(cat "$cgroup_path/memory.max" 2>/dev/null || echo "n/a")
    cpu=$(cat "$cgroup_path/cpu.max" 2>/dev/null || echo "n/a")

    # Umrechnung: Bytes → MB (nur bei Zahl)
    if [[ $mem =~ ^[0-9]+$ ]]; then
        mem_mb=$(($mem / 1024 / 1024))
        mem_text="${mem_mb} MB"
    elsec
        mem_text="$mem"
    fi

    echo "║ $(printf '%-10s' $cname) ║ $(printf '%-14s' "$mem_text") ║ $(printf '%-21s' "$cpu") ║"
done

echo "╚════════════╩════════════════╩═══════════════════════╝"

echo ""
echo "Tipp: Nutze 'docker stats c1 c2 c3' für Live-Ansicht."
echo "Tipp: Nutze 'docker inspect c1 c2 c3' für detaillierte Infos."
echo ""
echo "Container stoppen und entfernen..."
docker stop "${containers[@]}"
docker rm "${containers[@]}"
echo "Fertig!"