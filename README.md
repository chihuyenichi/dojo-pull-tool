# dojo-pull-tool

Tool kéo challenge files từ workspace pwn.college (`/challenge`) về máy cục bộ
trong **1 SSH connection** (tar stream qua stdout). Có thể chạy trực tiếp (native)
hoặc đóng gói bằng Docker.

## Yêu cầu

- Bash, `ssh` (openssh-client) — bắt buộc
- `rsync` (tùy chọn, cho fallback `--rsync`)
- Docker — chỉ cần nếu dùng cách chạy container

## Cài Docker (nếu chưa có)

```bash
sudo apt update && sudo apt install -y docker.io
sudo usermod -aG docker $USER   # rồi đăng xuất/đăng nhập lại
docker --version                # kiểm tra
```

## Setup key (một lần)

1. Lấy public key: `cat ~/.ssh/id_ed25519.pub`
2. Paste lên web pwn.college: **Settings → SSH Keys → Save**
3. Test kết nối: `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 hacker@dojo.pwn.college true`

> Workspace chỉ expose challenge **đang active** trong `/challenge` — muốn kéo
> challenge nào thì bật challenge đó trên web/dojo VM trước.

## Cấu hình (`pull.conf`)

Toàn bộ giá trị có thể override bằng biến môi trường:

| Biến | Mặc định | Ghi chú |
|---|---|---|
| `DOJO_USER` | `hacker` | user SSH trên workspace |
| `SSH_HOST` | `dojo.pwn.college` | host SSH |
| `KEY_PATH` | `~/.ssh/id_ed25519` | private key |
| `OUT_DIR` | `<tool>/outputs` | nơi file rơi về |

## Cách dùng — native (không cần Docker)

```bash
./pull.sh                    # kéo toàn bộ /challenge -> outputs/
./pull.sh 'babyfmt'          # kéo file khớp regex (ERE)
./pull.sh -m pwn.babysuid    # kéo theo prefix module
./pull.sh -n                 # dry-run: chỉ liệt kê, không kéo
./pull.sh -o /tmp/dir        # override thư mục output
./pull.sh -v                 # verbose
./pull.sh --rsync            # fallback bằng rsync
```

## Cách dùng — Docker

```bash
./run-docker.sh              # build image lần đầu (nếu chưa có) + pull
./run-docker.sh -n           # dry-run trong container
./run-docker.sh 'babyfmt'    # pattern — file vẫn rơi về ./outputs trên host
```

Container mount:
- `~/.ssh/id_ed25519` → `/run/ssh-key` (read-only)
- `./outputs` → `/outputs`
- `./pull.conf` → `/app/pull.conf` (đổi config không cần rebuild)

Hoặc dùng compose:

```bash
docker compose build
docker compose run --rm pull -n
docker compose run --rm pull           # pull thật
```

## Troubleshooting

| Lỗi | Nguyên nhân / cách xử lý |
|---|---|
| `Permission denied (publickey)` | Key chưa đăng ký trên web, hoặc user sai — phải là `hacker@dojo.pwn.college` |
| `Cannot connect to the Docker daemon` | Daemon chưa chạy: `sudo systemctl start docker`; hoặc bạn chưa có trong group docker |
| `No matching entries in /challenge` | Chưa bật challenge nào trên dojo — mở challenge đó trước rồi pull |
| `sudo: a password is required` khi build | Chạy `sudo usermod -aG docker $USER` + re-login |

## Cấu trúc thư mục

```
dojo-pull-tool/
├── pull.sh              # tool chính
├── pull.conf            # cấu hình (ENV override được)
├── Dockerfile           # image alpine + openssh-client + rsync + bash
├── docker-compose.yml   # service pull
├── run-docker.sh        # wrapper build + run
├── .dockerignore
├── PLAN.md              # kế hoạch + kết quả xác minh
├── README.md
└── outputs/             # file pull về nằm ở đây
```
