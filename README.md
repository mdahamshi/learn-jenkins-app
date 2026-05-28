# Jenkins CI/CD Pipeline — React App on k3s

A fully automated CI/CD pipeline that builds, tests, containerizes, and deploys a React application to a **k3s Kubernetes cluster** using **Jenkins**, **Docker**, **GitHub Container Registry**, and **Kustomize** — triggered by a **local Gitea** webhook over an internal network.

## Pipeline Architecture

```
Gitea Push (local, Coolify Docker)
    │
    ▼
Gitea Webhook (internal network)
    │
    ▼
┌────────────────────────────────────────────────────────┐
│              Jenkins (Coolify Docker on Proxmox)        │
│              (not exposed, internal only)               │
│                                                         │
│  ┌──────────┐  ┌────────────┐  ┌────────────────────┐ │
│  │  Build   │  │   Tests    │  │ Docker Build &      │ │
│  │ npm ci   │  │ ┌────────┐ │  │ Push to GHCR        │ │
│  │ npm run  │  │ │ Unit   │ │  │ (via GitHub token)  │ │
│  │ build    │  │ │ Jest   │ │  ├────────────────────┤ │
│  └──────────┘  │ ├────────┤ │  │ ghcr.io/.../app    │ │
│                │ │ E2E    │ │  │ :latest + :$BUILD   │ │
│                │ │ Playwr.│ │  └────────┬───────────┘ │
│                │ └────────┘ │           │              │
│                └────────────┘           ▼              │
│                                ┌────────────────────┐ │
│                                │  Deploy Staging     │ │
│                                │  kubectl apply -k   │ │
│                                │  k8s/staging        │ │
│                                └────────┬───────────┘ │
│                                         ▼              │
│                                ┌────────────────────┐ │
│                                │  Staging E2E        │ │
│                                │  Playwright vs      │ │
│                                │  staging ingress    │ │
│                                └────────┬───────────┘ │
│                                         ▼              │
│                                ┌────────────────────┐ │
│                                │  Deploy Prod        │ │
│                                │  kubectl apply -k   │ │
│                                │  k8s/prod           │ │
│                                └────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|---|---|
| **CI/CD** | Jenkins (Declarative Pipeline, via Coolify Docker) |
| **App** | React (Create React App) |
| **Testing** | Jest (unit), Playwright (E2E) |
| **Container Registry** | GitHub Container Registry (GHCR) |
| **Orchestration** | k3s (lightweight Kubernetes) |
| **Deployment** | Kustomize (k8s/base → staging/prod overlays) |
| **Trigger** | Gitea webhook (local, internal network) |
| **Hosting** | Proxmox → Coolify (Docker) → Jenkins |

## Jenkins Pipeline Stages

### 1. Build
- `node:18-alpine` container
- `npm ci` for reproducible installs
- `npm run build` produces static files
- Validates `build/index.html` exists

### 2. Tests (parallel)
- **Unit:** Jest with JUnit reporter, results published in Jenkins
- **E2E:** Playwright against local `serve` of the build, HTML report published

### 3. Docker Build & Push
- Authenticates to `ghcr.io` using stored GitHub token credential
- Builds nginx-based image serving the static build
- Tags as `:${BUILD_NUMBER}` and `:latest`
- Pushes both tags to GHCR

### 4. Deploy Staging
- Retrieves k3s kubeconfig from Jenkins credential store
- Patches `newTag` in `k8s/staging/kustomization.yaml` with the build number
- Applies Kustomize overlay → creates/updates resources in `staging` namespace
- Waits for rollout to complete
- Captures ingress host for staging URL

### 5. Staging E2E
- Runs Playwright tests against the live staging environment
- Validates the deployment end-to-end before promoting to production

### 6. Deploy Prod
- Same flow as staging but applies to `default` namespace
- Records deployment timestamp
- Patches image tag, applies kustomization, verifies rollout

## Kubernetes Structure (k3s)

```
k8s/
├── base/                  # Shared resources
│   ├── deployment.yaml    # Deployment (1 replica, port 80)
│   ├── service.yaml       # NodePort service
│   ├── ingress.yaml       # Ingress with placeholder host
│   └── kustomization.yaml
├── staging/
│   ├── kustomization.yaml # Overlay: namespace=staging, image tag
│   ├── namespace.yaml
│   └── ingress-patch.yaml # Host: learn-staging.k3.l
└── prod/
    ├── kustomization.yaml # Overlay: namespace=default, image tag
    └── ingress-patch.yaml # Host: learn.k3.l
```

Kustomize overlays keep staging and prod configs DRY. The Jenkins pipeline patches the image tag (`newTag`) dynamically before applying.

## Credentials Managed in Jenkins

| Credential ID | Type | Purpose |
|---|---|---|
| `github-token` | Secret text | Docker login to GHCR |
| `k3s-kubeconfig` | Secret file (base64) | kubectl authentication to k3s cluster |

## Prerequisites

- Jenkins instance with Docker pipeline support
- k3s cluster with ingress controller
- Gitea repository with webhook pointing to Jenkins (internal network)
- Jenkins credentials configured as above

## Local Development

```bash
npm install
npm start          # http://localhost:3000
npm test           # unit tests
npx playwright test  # E2E tests
```

## Docker Builds

```bash
# Build using pre-compiled assets (Jenkins-style)
docker build -t my-app .

# Full multi-stage build (no host npm needed)
docker build -f Dockerfile.fullbuild -t my-app .
```

## What I Learned

- Running Jenkins as a Coolify-managed Docker container on Proxmox (not exposed)
- Using Gitea webhooks over the internal network to trigger Jenkins builds
- Writing Declarative Pipelines with multi-stage, parallel branches
- Building and pushing Docker images to GHCR inside a Jenkins pipeline
- Managing credentials securely in Jenkins
- Deploying to k3s using kubectl + Kustomize
- Running E2E tests against deployed staging environments
- Structuring Kubernetes manifests with Kustomize overlays for staging/prod

## Acknowledgments

Based on **Valentin Despa — Jenkins: Jobs, Pipelines, CI/CD (11h)** [course](https://www.udemy.com/course/jenkins-ci-cd-pipelines-devops-for-beginners), extended with k3s deployment instead of Netlify.
