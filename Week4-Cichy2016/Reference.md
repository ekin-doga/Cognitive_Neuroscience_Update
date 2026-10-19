## Week 4 – Hierarchical processing in AlexNet

### Data on Sciebo
```
CNU/Week4/animals_objects/      # 120 images: 3 kinds × 4 concepts × 10 photos
├── animal_lion_1.jpg … animal_lion_10.jpg
├── animal_flamingo_1.jpg …     # animals: lion, flamingo, koala, iguana
├── fruit_banana_1.jpg …        # fruit:   banana, pineapple, strawberry, orange
├── object_teapot_1.jpg …       # objects: teapot, violin, backpack, mailbox
└── …
```
File names must be `<kind>_<concept>_<number>.<ext>`, with no underscores inside the parts. The notebook reads kinds, concepts and the number of photos from the file names, so another set only needs other files (add a new kind to `KINDS` in section 3).

The images were chosen from `Selection20_resized` with `Stimuli_hunt/Week4_selection/week4_animal_object_selection.ipynb` (not part of this repo). That notebook also exports `selection.csv` with the original file name and source of every image.

### Credits
> Cichy, R. M., Khosla, A., Pantazis, D., Torralba, A., & Oliva, A. (2016). Comparison of deep neural networks to spatio-temporal cortical dynamics of human visual object recognition reveals hierarchical correspondence. *Scientific Reports, 6*, 27755.

> Krizhevsky, A., Sutskever, I., & Hinton, G. E. (2012). ImageNet classification with deep convolutional neural networks. *Advances in Neural Information Processing Systems, 25*.

> Hebart, M. N., Dickter, A. H., Kidder, A., Kwok, W. Y., Corriveau, A., Van Wicklin, C., & Baker, C. I. (2019). THINGS: A database of 1,854 object concepts and more than 26,000 naturalistic object images. *PLoS ONE, 14*(10), e0223792.

> Kriegeskorte, N., Mur, M., Ruff, D. A., Kiani, R., Bodurka, J., Bandettini, P. A., & Tanaka, K. (2008). Matching categorical object representations in inferior temporal cortex of man and monkey. *Neuron, 60*(6), 1126–1141.

Most images come from THINGS, some from the ImageNet validation set: they may only be used for non-commercial research and education, so share them read-only and only with the class.
