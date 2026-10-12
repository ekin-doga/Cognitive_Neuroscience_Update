## Week 4 – Trained vs untrained AlexNet

### Data on Sciebo
```
CNU/Week4/images/
├── zebra_photo.jpg    # photo of a zebra
├── zebra_toy.jpg      # toy zebra
├── panda_photo.jpg    # photo of a giant panda
├── panda_toy.jpg      # plush panda
├── plane_photo.jpg    # photo of an airliner
├── plane_toy.jpg      # toy plane
├── banana_photo.jpg   # photo of a banana
└── banana_toy.jpg     # plush banana
```
The notebook also reuses `zebra_photo` and `plane_photo` from `CNU/Week3/images/` for the classification part.

Any image format works (`.jpg`, `.png`, `.webp`). The names must be exactly `<category>_photo` and `<category>_toy`. To use another category, rename its two files and change `CATEGORIES` at the top of section 5.

### Credits
> Cichy, R. M., Khosla, A., Pantazis, D., Torralba, A., & Oliva, A. (2016). Comparison of deep neural networks to spatio-temporal cortical dynamics of human visual object recognition reveals hierarchical correspondence. *Scientific Reports, 6*, 27755.

> Krizhevsky, A., Sutskever, I., & Hinton, G. E. (2012). ImageNet classification with deep convolutional neural networks. *Advances in Neural Information Processing Systems, 25*.

If you use ImageNet images: they may only be used for non-commercial research and education, so share them read-only and only with the class.
