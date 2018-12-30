# Quack!
An object detection experiment with CoreML and Vision.

![](https://user-images.githubusercontent.com/22856066/50550279-6f4c1c80-0c65-11e9-947b-ec8bf3146bb4.gif)

## What is this?
Quack detects (and tracks) ducks, with the help of machine learning. Actually, it should be a matter of replacing the model to track just about anything.


## Why ducks?
Because otherwise this would be yet another Cat App. Besides, I have a plenty supply of ducks nearby. 

And ducks can fly.


## That means you can track flying ducks?
Nay. Gathering and annotating training data is time consuming. I work for a living.


## So, how do you track ducks?
The app captures video from the iPhone back-facing camera. Each frame is then used as the input for a CoreML model that outputs predictions on each frame. The object detection model was created with [Turi Create](https://github.com/apple/turicreate), which uses a re-implementation of [TinyYOLO](https://pjreddie.com/darknet/yolov2/). Object tracking is implemented using these predictions (but not with Vision object tracking).


## Humm... not that much machine learning going on in there?
My first option was to use *Darknet* (YOLO implementation), but Turi Create simplifies the ML pipeline significantly. For more sophisticated uses, one could start with Darknet, translate the model to TensorFlow with *darkflow*, and then again to CoreML using *tfcoreml*. Or modify one of Keras implementations of YOLO and then convert the model to CoreML.


## Planning to buy a new Mac and a couple of eGPUs?
Show me the money.


## Why didn't you include the model?
My model is most likely overfitted to a particular set of ducks. It wouldn't be much help.


## Where's the Medium article?
I have nothing to add to the generally nice documentation and examples from Apple (or to the usually average other stuff out there). I hope the code provides a good example on how to use CoreML and Vision together.


## Were any kind of waterfowl hurt during the course of this experiment?
Seriously? No.
