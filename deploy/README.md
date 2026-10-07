# Auto-deploy tangen.co.id

`git push` ke `main` -> GitHub Actions (`.github/workflows/deploy.yml`) membangun situs dan mempublikasikan hasilnya
ke branch `deploy` -> `tangen-pull.timer` di VPS (tiap 30 detik) menarik branch itu dan menukar rilis lewat symlink.
Situs ter-update dalam ±1-2 menit setelah push.

| Apa | Di VPS |
|---|---|
| Skrip | `/usr/local/sbin/tangen-deploy` (salinan: `deploy/pull.sh`) |
| Timer / service | `tangen-pull.timer`, `tangen-pull.service` (salinan: `deploy/`) |
| Klon branch deploy + kunci | `/opt/tangen-site`, `/etc/tangen/deploy_key` (read-only) |
| Rilis | `/var/www/tangen-releases/<sha>` (3 terakhir); `/var/www/tangen.co.id` adalah symlink ke rilis aktif |

```bash
journalctl -u tangen-pull -n 20                    # log deploy
systemctl list-timers tangen-pull.timer            # jadwal cek berikutnya
/usr/local/sbin/tangen-deploy                      # paksa cek/deploy sekarang
ln -sfn /var/www/tangen-releases/<sha> /var/www/tangen.co.id.tmp && mv -T /var/www/tangen.co.id.tmp /var/www/tangen.co.id   # rollback
```
