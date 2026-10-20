## Week 2 – Meet AlexNet

### Data on Sciebo
```
CNU/Week2/
├── example.jpg              # the one image students classify
├── unknown_giraffe.jpg      # an animal with no ImageNet label
└── unknown_helicopter.jpg   # a vehicle with no ImageNet label
```

Pick an `example.jpg` that AlexNet gets right with a fairly confident first guess and sensible 2nd–5th guesses, such as a golden retriever, a banana or a coffee mug. Week 3 is where the hard cases come in.

For section 5 ("Things AlexNet has no label for"), add an animal and a vehicle that have no ImageNet label, e.g. a giraffe and a helicopter, named `unknown_<name>`. They go in the same folder as `example.jpg`.

AlexNet's weights are downloaded automatically the first time the notebook runs (about 230 MB), just like ResMem's, so the servers need internet access.

### Credits
> Krizhevsky, A., Sutskever, I., & Hinton, G. E. (2012). ImageNet classification with deep convolutional neural networks. *Advances in Neural Information Processing Systems, 25*.
