/* Made for Portland Light Festival - CETI Constellations 
    A collection of kinect scripts that employ glitch aesthetics
   Processing Code By Max Ettel
   Shader Code by Yori Kvitchko
   Glitch Video Source & Creative Support by Alan Page
   General Project Support from Sarah Bailey & Elyssa Kelly
*/

import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.video.*;

Kinect kinect;
float[] depthLookUp = new float[2048];

//image and shader initialization
PImage dMap; 
PImage cMap;
PImage finalImg;
PImage fullImg;
PShader sh;
Movie mov;

//scaling for display
float yScale;
float xMove;

//people selection 
float threshMin = 1.1;
float threshMax = 3;

//room selection
float roomMin = 1.5;
float roomMax = 12;

//points for scan function
float scanPts[] = {0,2.5,4,5.5,7,9.5,11};
int closeIndex;
int farIndex;

//for rotating lines function
float rotTheta = 0;

//for singleSkip
int breakPt;

//for multiSkip
int skippedLines[] = new int[50];
int skipAmt;
boolean skipLine = false;

//values to be sent to the shader
float horiVal = 0;
float vertVal = 0;
float wheelVal = 0;

//for circle function
/* circArray guide
index +
0 = current x position
1 = current y position
2 = target x position
3 = target y position
4 = size
5 = target size
6 = calculated x movement per frame
7 = calculated y movement per frame
8 = initial distance from target
*/
int cCount = 12;
float circArray[] = new float[cCount*9];
color circColor[] = new color[cCount];

//pallette system
color pallette[] = {
  color(255,241,151),
  color(242,206,126),
  color(242,146,84),
  color(234,113,31),
  color(242,97,34),
  color(232,146,119),
  color(81,33,232),
  color(139,95,224),
  color(189,118,226) };
  
//general booleans for function/method initialization and viewing information about what's being run  
boolean devMode = false;
boolean init = true;
boolean glitchInit = false;

//for the glitch functions
int setGlitch = 0;
int glitchLim = round(random(10,20));
int glitchVar = 0;
int glitchChooser[] = {1,2,3};
int prevGlitch = 4;

//determines which code is run
int viewer = 0;
int pMin = 0;

//for devMode
String glitchTest = "No Glitch ";
String glitchTimer = "0";

void setup(){
  fullScreen(P3D);
  kinect = new Kinect(this);
  frameRate(30);
  kinect.initDepth(); 
  kinect.initVideo();
  dMap = createImage(kinect.width, kinect.height, RGB);
  cMap = kinect.getVideoImage();
  finalImg = createImage(kinect.width, kinect.height, RGB);
  fullImg = createImage(width/2, height/2, RGB);
 
    //calculates how much to scale and to move the final result once it's been run
    yScale = float(height)/float(kinect.height);
    xMove = (float(width)-(float(kinect.width)*yScale))/3.33333;
  
  //populates depth lookup array with values
  for(int i = 0; i<depthLookUp.length; i++){
    depthLookUp[i] = rawDepthToMeters(i);
  }
  
  //initialize video & shader
  mov = new Movie(this, "glitch.mp4");
  mov.loop();
  sh = loadShader("filter.glsl");
  
}

void draw(){
  background(0);
  timer(10);
  
  pushMatrix();
  scale(yScale);
   translate(xMove,0);
   
   //determines which base function is run
  if(viewer==0){
     kinectScan(0.75,1);
  }
  
  else if(viewer==1){
   depthMap(1,1);
   compInterpolate(dMap, finalImg, 15);
  }
  
  else if(viewer==2){
    glitchVideo();
  }
  
  else if(viewer==3){
    depthMap(0,1);
    rotLines(30);
  }
  
  else if(viewer==4){
    depthMap(0,1);
    circLoop(dMap, finalImg);
  }
  
  //determines how to show the result of the currently run function, partially dependent on if setGlitch is active
  if(viewer==1){
   image(finalImg,0,0); 
  }
  else if(viewer==4){
   image(finalImg,0,0); 
  }
  
 
  else if(setGlitch > 0 && viewer==1){
   glitchApp(finalImg, finalImg);
   image(finalImg,0,0);
  }
  
  else if(setGlitch>0 & viewer==4){
    glitchApp(finalImg, finalImg);
   image(finalImg,0,0);
  }
  popMatrix();
  
  if(setGlitch > 0 && viewer==0 || viewer==2 || viewer==3){
    canvasToImage();
    glitchApp(fullImg,fullImg);
    pushMatrix();
    scale(2);
    translate(xMove,0);
    image(fullImg,0,0);
    popMatrix();
  }
  
  if(devMode==true){
  textSize(28);
  fill(100);
  text(glitchTest, width*.25, height*.75);
  text(glitchTimer, width*.25, height*.85);
  }
  
}

/* kinect & temporal code */

// converts values outputted from the kinect to meters
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

/* generates depth map to be used by the kinect
cMode = 1 Makes a colored DepthMap
cMode = 2 make a Grayscale DepthMap
dMode = 1 Sets depth thresholds to a narrow defined value
dMode = 2 sets depth thresholds to a wide defined value intended for a whole room
*/

void depthMap(int cMode, int dMode){
  int[] depth = kinect.getRawDepth();
  float dMin = 0;
  float dMax = 0;
  
   if(dMode==1){
         dMin = threshMin;
         dMax = threshMax;
       }
       else{
        dMin = roomMin;
        dMin = roomMax;
       }
  
  for(int y = 0; y<kinect.height; y++){
     for(int x = 0; x<kinect.width; x++){
       int index = x+y*kinect.width; 
       int rawDepth = depth[index];
       float calcDepth = depthLookUp[rawDepth];

       //if cMode is 1 create colored depth map
       if(cMode==1){
         if(calcDepth > dMin && calcDepth < dMax){
           float r = map(calcDepth, dMin, dMax, 0, 255);
           float g = map(x,0,kinect.width, 255,0);
           float b = map(y,0,kinect.height, 0, 255);
           dMap.set(x,y,color(r,g,b));
         }
         
         else{
          dMap.set(x,y,color(0)); 
         }
       }
       
       else{
          if(calcDepth > dMin && calcDepth < dMax){
            float bright = map(calcDepth, threshMin, threshMax, 255,0);
           dMap.set(x,y,color(bright));
         }
         
         else{
          dMap.set(x,y,color(0)); 
         }
       }
     }
  }
  dMap.updatePixels();
}

void timer(int lim){
  int minute = (millis()/1000)/lim;
  int gTimer = millis()/1000;
  if(minute==pMin+1){
    viewer++;
    imageReset(finalImg,0);
    if(viewer>=5){
     viewer = 0;
    }
    
    pMin = minute;
    init = true;
     println(viewer);
  }
  
  //timer for glitch effects
  if(gTimer==glitchLim){
    if(setGlitch==0){
    int glitchRNG = round(random(2));
    setGlitch = glitchChooser[glitchRNG];
    for(int i = 0; i<glitchChooser.length; i++){
     if(glitchChooser[i] == setGlitch){
       glitchChooser[i] = prevGlitch;
     }
    }
    glitchInit = true;
    glitchLim+=round(random(10));
    glitchTest = "Glitch Triggered " + setGlitch;
    }
    else if(setGlitch>0){
     prevGlitch = setGlitch;
     setGlitch = 0;
     glitchLim+=round(random(45));
     glitchTest = "Glitch Done ";
    }
  }
  glitchTimer = "Time until glitch " + (glitchLim-gTimer);
}

void glitchApp(PImage gInput, PImage gOutput){
  //copies canvas over to editable image
  if(viewer==0 || viewer==2 || viewer==3){
   canvasToImage(); 
  }
 
  if(glitchInit==true){
    //adds initial values to filters that require numerical arguments
   if(setGlitch==1){
     glitchVar = round(random(50));
   }
   else if(setGlitch==4){
     glitchVar = round(random(20));
   }
   glitchInit=false;
  }
  if(setGlitch==1){
     compInterpolate(gInput,gOutput, glitchVar);
   }
   else if(setGlitch==2){
     singleSkip(gInput, gOutput);
   }
   else if(setGlitch==3){
     multiSkip(gInput, gOutput);
   }
   else if(setGlitch==4){
     resDrop(gInput, gOutput,glitchVar);
   }
}

/* Cool functions */

//creates a scanning effect in the space its looking 
void kinectScan(float sizer, float brightThresh){
  background(0);
  noFill();
   
  if(init == true){
   closeIndex = round(random(0,pallette.length-1));
   farIndex = round(random(0,pallette.length-1)); 
   init = false;
  }
  
  color close = pallette[closeIndex];
  color far = pallette[farIndex];
  int depth[] = kinect.getRawDepth();
  cMap.loadPixels();
  
  for(int i = 0; i<scanPts.length; i++){
   float dMin = scanPts[i];
   float dMax = scanPts[i]+sizer;
   
   for(int y = 0; y<kinect.height; y+=3){
      for(int x = 0; x<kinect.width; x+=3){
         int index = x+y*kinect.width; 
         int rawDepth = depth[index];
         float calcDepth = depthLookUp[rawDepth];
         
         float r = map(calcDepth,roomMin, roomMax, red(close),red(far));
         float g = map(calcDepth, roomMin, roomMax, green(close), green(far));
         float b = map(calcDepth, roomMin, roomMax, blue(close), blue(far));
         
         float vidBright = brightness(cMap.pixels[index]);
         stroke(r,g,b);
         
           if(calcDepth > dMin && calcDepth < dMax && vidBright>brightThresh){
           rect(x,y,2,2);
         }
      }
   }
   scanPts[i]+=0.05;
    if(scanPts[i] > roomMax){
          scanPts[i] = 0; 
         }
  }
}

//has 3d lines that rotate in a weird way
void rotLines(float lineMax){
  background(0);
  stroke(255);
  float rotRadius = random(1,7);
  float rX = sin(rotTheta)*rotRadius;
  float rY = cos(rotTheta)*rotRadius;
  
  dMap.loadPixels();
  for(int y = 0; y<kinect.height; y+=4){
     for(int x = 0; x<kinect.width; x+=4){
      int index = x+y*kinect.width;
       float d = brightness(dMap.pixels[index]); 
       
       if(d>0){
        float z = 0; 
        float z2 = map(d, 1,255, 0, lineMax);
        float x2 = x+rX;
        float y2 = y+rY;
        
        line(x,y,z,x2,y2,z2);
       }
       
     }
  }
}
//draws circles that move around the screen, masked by the pixels within the depth threshold

void circLoop(PImage input,PImage output){
 for(int i = 0; i<cCount; i++){
   if(init==true){
    circInit(i); 
    circDraw(input,output, i, circColor[i]);
   }
   else{
    circMove(i);
    circDraw(input,output, i, circColor[i]);
   }
 }
 if(init==true){
  init = false; 
 }
 output.updatePixels();
}

void circInit(int i){
  int index = i*9;
  //set current position
  circArray[index] = round(random(kinect.width));
  circArray[index+1] = round(random(kinect.height));
  //set target position
  circArray[index+2] = round(random(kinect.width));
  circArray[index+3] = round(random(kinect.height));
  //set size and target size
  circArray[index+4] = round(random(kinect.height/10, kinect.height/3));
  circArray[index+5] = round(random(kinect.height/10, kinect.height/3));
  circColor[i] = color(pallette[round(random(1,pallette.length-1))]);
  distCalc(i);
}

void circMove(int i){
  int index = i*9;
  circArray[index]+=circArray[index+6];
  circArray[index]+=circArray[index+7];
  if(circArray[index] == circArray[index+2] && circArray[index+1]==circArray[index+3] || circArray[index]<=0 || circArray[index]>=width || circArray[index+1]<=0 || circArray[index+1]>=height){
   circArray[index+2] = round(random(kinect.width));
   circArray[index+3] = round(random(kinect.height));
   circArray[index+4] = circArray[index+5];
   circArray[index+5] = round(random(kinect.height/10, kinect.height/3));
   distCalc(i);
  }
}

void circDraw(PImage input,PImage output,int i, color c){
  input.loadPixels();
  int index = i*9;
  float dist = sqrt(sq(abs(circArray[index]-circArray[index+2]))+sq(abs(circArray[index+1]-circArray[index+3])));
  int sizer = round(map(dist,0,circArray[index+8],circArray[index+4],circArray[index+5]));
  
  for(int r = 0; r<sizer; r++){
    float tI = map(sizer, 0, kinect.height/3, 0.001, 0.05);
    for(float theta = 0; theta<PI*2; theta+=tI){
      int x = round(circArray[index]+sin(theta)*r);
      int y = round(circArray[index+1]+cos(theta)*r);
     
      if(x>0 && x<kinect.width && y>0 && y<kinect.height){
         int dIndex = x+y*kinect.width;
          float bright = brightness(input.pixels[dIndex]);
          if(bright>0){
        output.set(x,y,c);
          }   
      }
    }
  }
}

void distCalc(int i){
  int index = i*9;
  float xDist = abs(circArray[index]-circArray[index+2]);
  float yDist = abs(circArray[index+1]-circArray[index+3]);
  float totalDist = sqrt(sq(xDist)+sq(yDist));
  float speed = map(totalDist,0,sqrt(sq(kinect.width)+sq(kinect.height)), 60,240);
  circArray[index+6] = xDist/speed;
  circArray[index+7] = yDist/speed;
  circArray[index+8] = totalDist;
  
  if(circArray[index] > circArray[index+2]){
    circArray[index+6]*=-1;
  }
  
  if(circArray[index+1] > circArray[index+3]){
   circArray[index+7]*=-1; 
  }
}

/* shader stuff */
void glitchVideo(){  
 mov.read();
 sh.set("hori",horiVal);
 sh.set("vert", vertVal);
 sh.set("wheel",wheelVal);
 sh.set("movTexture",mov);
 sh.set("depthTexture", kinect.getDepthImage());
shader(sh);
image(kinect.getVideoImage(),0,0);
resetShader();
}

/* ---------------------------------------
          image filters 
--------------------------------------------*/
//resets the image between scripts, colMode = 0 sets it to black, 1 sets it to white
void imageReset(PImage output, int colMode){
  for(int y = 0; y<output.height; y++){
     for(int x = 0; x<output.width; x++){
       if(colMode == 0){
      output.set(x,y,color(0)); 
       }
       else if(colMode == 1){
        output.set(x,y,color(255)); 
       }
     }
  }
  output.updatePixels();
}

void canvasToImage(){
 loadPixels();
 for(int y = 0; y<fullImg.height; y++){
  for(int x = 0; x<fullImg.width; x++){
   int index = x+y*width;
   int cnvIndex = index*2;
   color c = color(pixels[cnvIndex]);
   fullImg.set(x,y,c);
  }
 }
 fullImg.updatePixels();
}

//compInterpolate does a pixelsorting style effect that blends values together
void compInterpolate(PImage input,PImage output, float thresh){
 input.loadPixels();
  int count = 0;
  float imgArray[] = new float[(input.width*input.height)*3];
  boolean overWrite = false;
  boolean buildPixels = false;
  //run through image and write values to the array
  float sR = 0;
  float sG = 0; 
  float sB = 0;
  for(int y = 0; y<input.height; y++){
     for(int x = 0; x<input.width; x++){
      int index = x+y*input.width;
      float r = red(input.pixels[index]);
      float g = green(input.pixels[index]);
      float b = blue(input.pixels[index]);
      
      if(x==0){
       overWrite = true; 
      }
      else if(x==input.width-1){
       overWrite = true; 
       buildPixels = true;
      }
      else {
       float rDiff = abs(sR-r);
       float gDiff = abs(sG-g);
       float bDiff = abs(sB-b);
       float avgDiff = (rDiff+gDiff+bDiff)/3;
       
       if(avgDiff > thresh){
         overWrite = true;
         buildPixels = true;
       }
       count+=1;
      }
      if(buildPixels==true){
       float jR = 0; 
       float jG = 0;
       float jB = 0;
       int arrayPos = (index-count)*3;
       for(int j = 0; j<count; j++){
         jR = abs(map(j,0,count,sR,r));
         jG = abs(map(j,0,count,sG,g));
         jB = abs(map(j,0,count,sB,b));
         imgArray[arrayPos+0] = jR;
         imgArray[arrayPos+1] = jG;
         imgArray[arrayPos+2] = jB;
         buildPixels = false;
         arrayPos+=3;
       } // j
      }// build
      if(overWrite==true){
       sR = r;
       sG = g;
       sB = b;
       count = 0;
       overWrite = false;
      }
     }
  } // end of writing 
  for(int y = 0; y<input.height; y++){
     for(int x = 0; x<input.width; x++){
      int index = x+y*input.width;
      int arrayIndex = index*3;
      float r = imgArray[arrayIndex+0];
      float g = imgArray[arrayIndex+1];
      float b = imgArray[arrayIndex+2];
      output.set(x,y,color(r,g,b));
     }
  }
  
  output.updatePixels(); 
}

//some minor analog effects
void singleSkip(PImage input, PImage output){
   if(init==true){
    breakPt = round(random(input.height*0.1, input.height*0.9));
    init = false;
  }
  int breakIndex = breakPt*input.width;
  int modIndex = breakIndex;
  input.loadPixels();
  for(int y = 0; y<input.height; y++){
     for(int x = 0; x<input.width; x++){
      output.set(x,y,color(input.pixels[modIndex]));
      modIndex++;
      if(modIndex>=input.pixels.length){
       modIndex = 0; 
      }
     }
  }
  output.updatePixels();

}

void multiSkip(PImage input, PImage output){
 if(init==true){
  skipAmt = round(random(1,skippedLines.length));
  
  //populate skipped lines array with lines to be skipped
  for(int i = 0; i<skipAmt; i++){
   skippedLines[i] = round(random(input.height)); 
  }
   init = false; 
   println(skippedLines.length, skipAmt);
   
 }
 
 input.loadPixels();
 boolean skipLine = false;
 for(int y = 0; y<input.height; y++){
  //figure out if the current line will be skipped
    for(int i = 0; i<skippedLines.length-1; i++){
     if(skippedLines[i] == y){
      skipLine = true;
      break;
     }
       else{
          skipLine = false; 
       }
    }
    int breakX = round(random(width*.05, width*.75));
    int modIndex = breakX+y*input.width;
    for(int x = 0; x<input.width; x++){
     int index = x+y*input.width;
     int modXVal = modIndex-(y*input.width);
     if(modXVal>=input.width){
      modIndex = y*input.width;
     }
     if(skipLine==true){
      output.set(x,y,color(input.pixels[modIndex])); 
     }
     else{
      output.set(x,y,color(input.pixels[index])); 
     }
     modIndex++;
    }
 }
 output.updatePixels();
}

void resDrop(PImage input, PImage output, int cellsize){
 int colIndex = 0;
 int colIterate = 0;
 color c = color(0);
 input.loadPixels();
 for(int y = 0; y<input.height; y++){
  for(int x = 0; x<input.width; x++){
    int index = x+y*input.width;
    if(colIndex==0 ||colIterate==colIndex){
     c = color(input.pixels[index]); 
     colIndex+=cellsize;
    }
    output.set(x,y,c);
    
    colIterate++;
  }
 }
 output.updatePixels();
}

/* ------------------------------------------
                inputs
---------------------------------------------*/

//kills the script if it freezes (ideally)
void keyPressed(){
 if(key=='`'){
  exit(); 
 }
 
 if(key=='1'){
   if(devMode==false){
   devMode=true;
   }
   else{
     devMode=false;
   }
 }
}
