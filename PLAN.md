# PLAN — Dojo Pull Tool (final)

## Vị trí
`/run/media/taing21/HuyenChi/daohuyenchi_server/CTF_downloads/practice/dojo-pull-tool/`

## Cấu trúc
```
dojo-pull-tool/
├── PLAN.md
├── README.md       # cách đăng ký key.pub, cách dùng
├── pull.sh         # tool chính (chmod +x)
├── pull.conf       # cấu hình
└── outputs/        # thư mục output MẶC ĐỊNH (tạo sẵn)
```

## pull.conf
- `DOJO_USER="hacker"`            (workspace SSH user — đúng như thực tế đã test)
- `SSH_HOST="dojo.pwn.college"`   (không phải ssh.pwn.college)
- `KEY_PATH="$HOME/.ssh/id_ed25519"`
- `OUT_DIR="$SCRIPT_DIR/outputs"`

## pull.sh
```
./pull.sh                # kéo tất cả /challenge -> outputs/
./pull.sh <regex>        # kéo file khớp pattern (vd 'babysuid_level1')
./pull.sh -m <module>    # kéo theo prefix (vd -m pwn.babysuid)
Flags: -o DIR | -n dry-run (list remote) | -v | --rsync
```
- Core: `ssh ... "$(remote_list_null) | tar czf - -C /challenge --null -T -" | tar xzf - -C "$OUT_DIR"`
- Danh sách NUL-separated (an toàn với tên file có space/ký tự đặc biệt)
- Tự mkdir đích, fail rõ ràng + hướng dẫn đăng ký key khi SSH `publickey` fail
- `--rsync` fallback nếu tar-stream lỗi

## Xác minh (đã chạy)
1. `bash -n pull.sh` — OK
2. SSH kết nối OK sau khi đăng ký `~/.ssh/id_ed25519.pub` lên web dojo
3. Pull thật `babyfmt_level1.0` -> `outputs/`, binary ELF còn chạy được
4. Pattern mode (`'babyfmt'`, `-m babyfmt`), dry-run, no-match (exit 3) — OK
5. Sửa trong lúc test: NUL-separation, `remote_list_human/null`, `|| true` no-match

## Đóng gói Docker (rev 3 — đã hoàn thành phần code)
- `Dockerfile` (alpine 3.20 + openssh-client + rsync + bash, non-root `pull`, entrypoint pull.sh)
- `.dockerignore`, `docker-compose.yml` (service `pull`, mounts key/outputs/conf)
- `run-docker.sh` (tự build lần đầu + `docker run` mount đúng)
- `pull.conf` đổi sang dạng `VAR="${VAR:-default}"` → ENV trong container thắng
- `pull.sh` ssh_cmd thêm `-o BatchMode=yes -o StrictHostKeyChecking=accept-new`
- `README.md` viết lại đầy đủ (tiếng Việt): yêu cầu, cài docker, setup key, dùng native/docker, troubleshooting

## Còn lại (chờ Docker trên máy)
1. User chạy: `sudo apt install -y docker.io && sudo usermod -aG docker $USER` + re-login
2. `docker build -t dojo-pull:latest .`
3. `./run-docker.sh -n` → dry-run trong container
4. `./run-docker.sh` → pull thật, file rơi về `./outputs` trên host
