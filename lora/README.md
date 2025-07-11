## lora/README.md
```markdown
# LoRA Files Directory

This directory contains the transformation-specific LoRA files for AI-Avatarka effects.

## Required Files

Each effect requires a corresponding `.safetensors` LoRA file:
ghostrider.safetensors          # Ghost Rider transformation
son_goku.safetensors           # Son Goku Super Saiyan
hulk.safetensors               # Hulk transformation
super_saian.safetensors        # Super Saiyan energy
westworld.safetensors          # Westworld robot reveal
samurai.safetensors            # Samurai warrior
kamehameha.safetensors         # Kamehameha energy beam
jumpscare.safetensors          # Jumpscare monster
melt_it.safetensors            # Melting transformation
mindblown.safetensors          # Head explosion
muscles.safetensors            # Muscle showcase
crush_it.safetensors           # Hydraulic press
fus_ro_dah.safetensors         # Force push effect
360.safetensors                # 360 degree rotation
vip_50_epochs.safetensors      # VIP red carpet
puppy.safetensors              # Puppy swarm
snow_white.safetensors         # Snow White princess
## File Requirements

- **Format**: SafeTensors (.safetensors)
- **Training**: Wan 2.1 compatible LoRA adaptations
- **Size**: Typically 100-500MB per file
- **Strength**: Configured in `prompts/effects.json`

## Adding New LoRA Files

1. Place `.safetensors` file in this directory
2. Add effect configuration to `prompts/effects.json`
3. Update `worker-config.json` options
4. Test with the new effect name

## Notes

⚠️ **These files are not included in the repository** due to:
- Large file sizes (several GB total)
- Licensing considerations  
- Storage limitations

You must obtain these files separately and place them here before deployment.