# 🎭 AI-Avatarka - Epic Avatar Transformations

Transform portraits into stunning animated avatars with cinematic special effects using Wan 2.1 video generation.

## ✨ Features

- **17 Epic Transformations**: Ghost Rider, Super Saiyan, Hulk, Westworld, and more
- **720P High Quality**: Professional-grade video output at 16 FPS
- **5-Second Videos**: Perfect length for social media and avatars
- **GitHub Actions CI/CD**: Fully automated deployment pipeline
- **Advanced AI**: Powered by Wan 2.1 with custom LoRA transformations

## 🚀 Quick Deploy (5 Minutes)

### 1. Fork/Clone Repository
```bash
git clone https://github.com/yourusername/ai-avatarka-worker.git
cd ai-avatarka-worker
2. Configure LoRA Downloads
bashpython setup_gdrive_ids.py
# Enter your Google Drive URLs for LoRA files
3. Push to Deploy
bashgit add .
git commit -m "Configure LoRA downloads"
git push origin main
4. Watch GitHub Actions Build! 🎬

Go to Actions tab in your GitHub repo
Watch automated build and deployment
Get container image URL from summary

5. Deploy to RunPod

Use the generated container image: ghcr.io/yourusername/ai-avatarka-worker:latest
Upload worker-config.json
Test with sample image!

🎬 Transformation Effects
EffectDescriptionTrigger🔥 Ghost RiderFlaming skull transformationghostrider⚡ Son GokuSuper Saiyan power upson_goku💚 HulkIncredible green transformationhulk🌟 Super SaiyanGolden energy aurasuper_saian🤖 WestworldRobotic face revealwestworld⚔️ SamuraiWarrior transformationsamurai💥 KamehamehaEnergy beam attackkamehameha👹 JumpscareMonster revealjumpscare🌊 MeltLiquid transformationmelt_it💣 Mind BlownHead explosionmindblown💪 MusclesShow off physiquemuscles🏗️ CrushHydraulic press effectcrush_it🌪️ Fus Ro DahForce push effectfus_ro_dah🔄 360 RotationSpin around360⭐ VIPRed carpet glamourvip_50_epochs🐶 PuppyCute puppy swarmpuppy🍎 Snow WhiteDisney princesssnow_white
🏗️ Architecture

Base Image: hearmeman/comfyui-wan-template:v2 (CUDA 12.8)
Models: Comfy-Org Wan 2.1 repackaged (~32GB)
LoRA Files: 17 transformation effects (~1.7GB)
Pipeline: GitHub Actions → GHCR → RunPod

Built with ❤️ for epic avatar transformations!

### `.gitignore`
Large model files
*.safetensors
*.bin
*.ckpt
*.pth
Python
pycache/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
IDEs
.vscode/
.idea/
*.swp
*.swo
OS
.DS_Store
Thumbs.db
Logs
*.log
logs/
Temporary files
tmp/
temp/
*.tmp
Environment variables
.env
.env.local

## 📋 Quick Checklist

Create these files in your repository:

- ✅ `.github/workflows/CI-test_handler.yml`
- ✅ `.github/workflows/CD-docker_deploy.yml`
- ✅ `worker-config.json`
- ✅ `test_input.json`
- ✅ `setup_gdrive_ids.py`
- ✅ `README.md`
- ✅ `.gitignore`

Then you'll have a complete GitHub Actions deployment pipeline! 🚀