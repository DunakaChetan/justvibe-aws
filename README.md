# AWS Deployment Guide (Step by Step)

## 1. First Git Push (create the deploy repo)
1. `git init`
2. Copy this entire `AWS/` folder (including `.github/workflows`) into the repo root.
3. `git add .`
4. `git commit -m "Add AWS deployment files"`
5. `git branch -M main`
6. `git remote add origin https://github.com/<your-org>/justvibe-aws-deploy.git`
7. `git push -u origin main`

## 2. Point Dockerfiles to your app repos
Edit these files and replace the placeholder GitHub URLs with your real repos:
- `AWS/backend.Dockerfile`
- `AWS/frontend.Dockerfile`

If the repos are private, add PAT-based auth to the `git clone` commands.

## 3. Set the public IP/domain inside tracked files
1. Open `AWS/docker-compose.yml` and replace `http://localhost` values
   (e.g., `CORS_ORIGIN` and the `API_BASE_URL` build arg) with `http://<EC2_PUBLIC_IP>`.
2. The `API_BASE_URL` build arg in `AWS/frontend.Dockerfile` writes
   `VITE_API_BASE_URL` before `npm run build`, so whatever value you set in
   `docker-compose.yml` is what the bundled frontend will use at runtime.

## 4. Add SSH key and GitHub secrets
1. Generate a deploy key if you don’t have one:
   ```bash
   ssh-keygen -t ed25519 -f justvibe-aws
   ```
2. Add the **public** key to `~/.ssh/authorized_keys` on the EC2 instance.
3. In the deploy repo settings → Secrets, add:
   - `EC2_HOST` = public IP/DNS
   - `EC2_USER` = `ubuntu` (or your user)
   - `EC2_SSH_KEY` = contents of the private key (`justvibe-aws`)
   > You will set up an additional PAT-based secret (`DEPLOY_REPO_TOKEN`) inside
   > the frontend and backend repos when wiring the auto-trigger in step 7.

## 5. Prepare the EC2 instance (no Docker Hub login needed)
1. Launch Ubuntu 22.04 (t3.small+ recommended).
2. Security group must allow inbound 22, 80, 8080.
3. SSH in and install Docker from the official repository:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg git
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
     https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   sudo usermod -aG docker ubuntu
   exit
   ```
4. Reconnect via SSH and verify the install (no Docker Hub login required):
   ```bash
   docker --version
   docker compose version
   docker buildx version
   ```
   These commands confirm the plugins are available through the `docker` CLI. Because the images build from your public GitHub repos, you never need to `docker login` on this server.

## 6. Manual test deploy (optional)
1. `ssh ubuntu@<EC2_PUBLIC_IP>`
2. `git clone https://github.com/<your-org>/justvibe-aws-deploy.git`
3. `cd justvibe-aws-deploy/AWS`
4. `chmod +x deploy.sh`
5. `./deploy.sh`
6. Verify:
   - Frontend → `http://<EC2_PUBLIC_IP>/`
   - Backend → `http://<EC2_PUBLIC_IP>:8080/health`

## 7. Automatic deploy with GitHub Actions
1. Keep `AWS/.github/workflows/deploy.yml` in the repo. It now listens to both
   pushes on `main` and `repository_dispatch` events (`frontend-updated`,
   `backend-updated`).
2. Every push or dispatch packages the `AWS` folder, uploads it to EC2, and runs `deploy.sh`.
3. To trigger from the frontend and backend repos:
   - Create a GitHub Personal Access Token (classic) with **repo** scope.
   - In each app repo, add a secret named `DEPLOY_REPO_TOKEN` containing the PAT.
   - Copy the corresponding template from `AWS/templates/frontend-notify.yml`
     or `AWS/templates/backend-notify.yml` into `.github/workflows/` of that repo.
   - Replace `https://github.com/<your-org>/justvibe-aws-deploy` with your deploy repo path.
   - On every push to `main`, the workflow will call the deploy repo’s
     `/dispatches` API, which in turn kicks off the EC2 deployment.

## 8. Updating the public IP later
1. Edit `AWS/docker-compose.yml` (and any other tracked files) to use the new IP/domain.
2. Commit & push so the workflow redeploys using the updated values.

Follow these steps in order to get the deploy repository online, configure AWS, update IPs, manage SSH keys, and keep deployments fully automated.***

