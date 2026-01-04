# Vaar Designs UI

React + Vite application with automated AWS deployment via GitHub Actions.

## 🚀 Quick Start

### Local Development

```bash
npm install
npm run dev
```

### Deployment

**Automated Deployment (Recommended):**
Push to `developer` or `main` branch, and GitHub Actions will automatically deploy to AWS!

**Quick Setup (10 minutes):**

1. 📖 Start with **[QUICK-START.md](./QUICK-START.md)** - Step-by-step setup guide
2. 🏗️ Read **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Understand the deployment flow
3. 📚 Reference **[GITHUB-DEPLOYMENT-GUIDE.md](./GITHUB-DEPLOYMENT-GUIDE.md)** - Detailed documentation

## 📚 Documentation

| Document                                                                 | Purpose                                   |
| ------------------------------------------------------------------------ | ----------------------------------------- |
| **[QUICK-START.md](./QUICK-START.md)**                                   | 5-minute setup guide - Start here!        |
| **[MANUAL-VS-AUTOMATED.md](./MANUAL-VS-AUTOMATED.md)**                   | Compare manual vs automated deployment    |
| **[GITHUB-DEPLOYMENT-GUIDE.md](./GITHUB-DEPLOYMENT-GUIDE.md)**           | Complete deployment documentation         |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)**                                 | Visual diagrams and architecture overview |
| **[terraform-github-actions-iam.tf](./terraform-github-actions-iam.tf)** | Terraform file for IAM user setup         |

## 🏗️ Infrastructure

This project uses Terraform-managed AWS infrastructure:

- **S3**: Static website hosting
- **CloudFront**: Global CDN with SSL
- **Route 53**: DNS management
- **ACM**: SSL certificates

Terraform code location: `C:\vaardesigns\terraform\vaar-terraform-ui`

## 🔧 Tech Stack

- **Frontend**: React 19 + Vite 7
- **Styling**: Tailwind CSS 4
- **Deployment**: GitHub Actions → AWS S3 + CloudFront
- **Infrastructure**: Terraform

## 📦 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy-to-aws.yml    # Automated deployment workflow
├── public/                       # Static assets
├── src/                          # React source code
├── package.json                  # Dependencies
├── vite.config.js               # Vite configuration
└── tailwind.config.js           # Tailwind configuration
```

## 🚀 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## 🔄 Deployment Workflow

```
Developer → git push → GitHub → GitHub Actions → Build → S3 → CloudFront → Live! 🎉
```

**Time from push to live:** ~8-10 minutes

## 🎯 Branch Strategy

- **`developer`**: Development branch - auto-deploys on push
- **`main`**: Production branch - auto-deploys on push

## 🔐 GitHub Secrets Required

Set these in GitHub repository settings (Settings → Secrets → Actions):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_S3_BUCKET`
- `AWS_CLOUDFRONT_DISTRIBUTION_ID`

See [QUICK-START.md](./QUICK-START.md) for setup instructions.

## 🐛 Troubleshooting

See [GITHUB-DEPLOYMENT-GUIDE.md](./GITHUB-DEPLOYMENT-GUIDE.md#troubleshooting) for common issues and solutions.

## 📝 Contributing

1. Create a feature branch from `developer`
2. Make your changes
3. Push to GitHub (tests run automatically)
4. Create pull request to `developer`
5. After review, merge to `developer`
6. Deploy to staging automatically
7. Merge to `main` for production

---

## React + Vite Template Info

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) (or [oxc](https://oxc.rs) when used in [rolldown-vite](https://vite.dev/guide/rolldown)) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh
