#!/usr/bin/env bash
# deploy/pull.sh (terpasang di VPS sebagai /usr/local/sbin/tangen-deploy) — dijalankan root oleh tangen-pull.timer tiap 30 detik di VPS.
# Menarik branch `deploy` (hasil build dari GitHub Actions) dan menukar rilis secara atomik lewat symlink.
# Tidak ada commit baru -> selesai tanpa melakukan apa pun. Rilis lama disimpan 3 terakhir untuk rollback.
set -euo pipefail

APP=/opt/tangen-site
WEB=/var/www/tangen.co.id          # symlink -> $RELEASES/<sha>
RELEASES=/var/www/tangen-releases
BRANCH=deploy

exec 9>/run/lock/tangen-deploy.lock
flock -n 9 || exit 0

export GIT_SSH_COMMAND="ssh -i /etc/tangen/deploy_key -o IdentitiesOnly=yes -o UserKnownHostsFile=/etc/tangen/known_hosts -o StrictHostKeyChecking=yes"
cd "$APP"
git fetch --quiet origin "$BRANCH"
remote=$(git rev-parse FETCH_HEAD)
local_rev=$(git rev-parse -q --verify HEAD || echo none)
[ "$local_rev" = "$remote" ] && exit 0

echo "[deploy] ${local_rev:0:7} -> ${remote:0:7}: $(git log -1 --format=%s FETCH_HEAD)"
install -d -m 755 "$RELEASES"   # harus bisa dilintasi nginx (www-data), kalau tidak situs 404
rel="$RELEASES/$remote"
rm -rf "$rel"; mkdir -p "$rel"
git archive FETCH_HEAD | tar -x -C "$rel"
if [ ! -s "$rel/index.html" ]; then
	echo "[deploy] GAGAL: index.html tidak ada di build, rilis dibatalkan." >&2
	rm -rf "$rel"; exit 1
fi
chmod -R u=rwX,go=rX "$rel"

ln -sfn "$rel" "$WEB.tmp" && mv -T "$WEB.tmp" "$WEB"   # rename atomik: tidak ada saat situs setengah terunggah
git reset --quiet --hard FETCH_HEAD
ls -1dt "$RELEASES"/*/ | tail -n +4 | xargs -r rm -rf   # simpan 3 rilis terakhir
echo "[deploy] selesai: ${remote:0:7}"
