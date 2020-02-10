# cannotKinect
An exploration of our relationship with failed technology using Processing + Kinect.   
Made for Portland Winter Light Festival - CETI Constellations. 

## credits 
*Processing Code by Max Ettel  
Shader Code by Yori Kvitchko  
Glitch Video Source & Creative Support by Alan Page  
General Project Support from Sarah Bailey & Elyssa Kelly*  

## What does it do?
A whole lot of stuff. So this has three different levels.  
1. The code that calls the primary & secondary effects
2. The primary effects
3. The secondary effects 
The first level is focused around the timer function. This function runs a timer for the entire time the sketch is run. When it reaches the limit set for each primary function it will switch the one that's currently run. There are also general functions for generating a depth map, as well as ones that perform actions dependent on the timer.  

### primary effects   
These are run dependent on the variable `viewer`.  
#### `viewer==0`: Kinect Scan  
This performs a scanning effect throughout the room
#### `viewer==1` : compInterpolate  
This generates a colored depth map that is then run through a script that detects points of high contrast and interpolates the pixels between them  
#### `viewer==2` : Glitch Video  
This uses the shader to generate a cutout from the kinects depth image, and then uses that as a mask for the `glitch.mp4` video file  
#### `viewer==3` : rotLines  
This takes a depthMap using `thresh` variables and creates a series of lines in 3D space that rotates around their intially drawn point.   
#### ` viewer==4` : circLoop
This takes a depthmap using `thresh` variables, and uses that as a mask on a series of circles that *paint* across an image as they move. 
### secondary effects  
These effects run on top of the primary ones. 
#### `setGlitch==1` : compInterpolate  
runs the edge interpolation code as detailed above.  
#### `setGlitch==2` : singleSkip  
Selects a *breakpoint* where the image will begin indexing, when it reaches the end it will begin indexing at the usual points. This is an attempt at replicating a similar analog effect.  
#### ` setGlitch==3` : multiSkip  
Where *singleSkip* makes a single breakpoint for the entire image. This sets breakpoints on a random amount of horizontal lines in the image, changing with every frame as it runs.  
#### `setGlitch==4` : resDrop  
This is an attempt at quickly dropping the resolution of the image without using cells. This only samples the image on a set other index. This biases primary horizontal.  

## setup
1. Requires [openKinect for Processing](https://github.com/shiffman/OpenKinect-for-Processing).  
2. Open the file in the processing IDE and locate the threshMin/Max & roomMin/Max variables.  
3. These variables determine the ranges for human cutouts (thresh), and the whole room.  
4. Adjust those variables to your environment.  
5. You should be good to go.  
**Note:** This was all developed with a Kinect 1.0 1414. Your results will vary with the the 1474.  
This currently does not suport Kinect 2.0.  

### known issues
* Occasionally when run after opening it will return a java error. Simply stop the sketch and restart it, then it should work.  
* Some of the glitch effects can be fairly resource intensive. This is due to how some of them are applied (where the canvas is being written to an image which is then modified). I've made attempts to improve this, however the inherent process has flaws.   
