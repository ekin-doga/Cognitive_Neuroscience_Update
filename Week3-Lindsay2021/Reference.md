## Week 3 – Classifying images with AlexNet

### Data on Sciebo
All images go in one folder, `CNU/Week3/images/`. Name each file `<object>_<version>`. The notebook finds the objects from the filenames, so adding a third object only means adding five more files. A missing version is simply left out.

```
CNU/Week3/images/
├── zebra_imagenet.jpg    # a photo from ImageNet (use validation images)
├── zebra_photo.jpg       # a new photo of a zebra, not from ImageNet
├── zebra_drawing.png     # a coloured drawing
├── zebra_outline.png     # a black-and-white line drawing
├── zebra_toy.jpg         # a toy zebra
├── plane_imagenet.jpg
├── plane_photo.jpg
├── plane_drawing.png
├── plane_outline.png
└── plane_toy.jpg
```

Object names must not contain an underscore (`teddybear`, not `teddy_bear`).

For section 4 ("When toys *do* work"), a second folder holds four objects as photo and toy:

```
CNU/Week3/toys/
├── zebra_photo.jpg    zebra_toy.jpg
├── panda_photo.jpg    panda_toy.jpg      # giant panda, plush panda
├── plane_photo.jpg    plane_toy.jpg      # airliner, toy plane
└── banana_photo.jpg   banana_toy.jpg     # banana, plush banana
```
These are the eight images of the old Week 4 folder (`CNU/Week4/images/`). The names must be exactly `<object>_photo` and `<object>_toy`; the correct ImageNet label for each object is set in `TOY_OBJECTS` at the top of section 4.


### Choosing the images
- **Objects:** zebra and plane. Zebra has a single ImageNet class (no species problem). For the plane, use an `airliner` photo; note that the ImageNet label `plane` is the carpenter's tool.
- **Drawings:** make wide or tall drawings square by adding white space around them, so the centre crop does not cut off the nose or tail.
- **Toys:** ImageNet has toy-like labels such as "teddy bear" and "toyshop", so a plush zebra may come out as "teddy bear". Check your images first, and then use the result in the discussion.

### Credits
> Lindsay, G. W. (2021). Convolutional neural networks as a model of the visual system: Past, present, and future. *Journal of Cognitive Neuroscience, 33*(10), 2017–2031.

> Krizhevsky, A., Sutskever, I., & Hinton, G. E. (2012). ImageNet classification with deep convolutional neural networks. *Advances in Neural Information Processing Systems, 25*.

> Deng, J., Dong, W., Socher, R., Li, L.-J., Li, K., & Fei-Fei, L. (2009). ImageNet: A large-scale hierarchical image database. *CVPR*.

ImageNet images may only be used for non-commercial research and education, so share them read-only and only with the class.
