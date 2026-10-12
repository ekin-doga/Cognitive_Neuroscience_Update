## Week 3 – Classifying images with AlexNet

### Data on Sciebo
Put the images in `CNU/Week3/`, one folder per set. Each **filename is shown as the image's name** in the notebook, so name files by what they show (`banana.jpg`, `dog_drawing.png`).

```
CNU/Week3/
├── 1_imagenet/              # ImageNet images (use validation images, which AlexNet was not trained on)
├── 2_same_category/         # the same categories as set 1, but not from ImageNet
└── 3_new_category/          # objects with no ImageNet label
```

About 6–10 images per set works well. Each image gets its own row of top-5 bars, so more images make long plots.

### Suggested images
- **Set 1:** pick 5 categories that are easy to photograph, such as `banana`, `coffee mug`, `golden retriever`, `tabby` (cat) and `mountain bike`, with 1–2 ImageNet images of each.
- **Set 2:** the same 5 categories made harder: your own photo on a messy desk, a drawing or cartoon, a toy version, an unusual viewpoint (a mug from above), or a peeled or sliced banana.
- **Set 3:** a face or selfie (ImageNet has no "person" class), a hand, a brain MRI, a painting from `Week0/art_images`, a tree, or an abstract pattern. Check each one with `find_labels()` in the notebook to make sure it really has no label.

AlexNet's weights are downloaded automatically the first time the notebook runs (about 230 MB), just like ResMem's.

### Credits
> Krizhevsky, A., Sutskever, I., & Hinton, G. E. (2012). ImageNet classification with deep convolutional neural networks. *Advances in Neural Information Processing Systems, 25*.

> Deng, J., Dong, W., Socher, R., Li, L.-J., Li, K., & Fei-Fei, L. (2009). ImageNet: A large-scale hierarchical image database. *CVPR*.

ImageNet images may only be used for non-commercial research and education, so share them read-only and only with the class.
