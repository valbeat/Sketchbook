import processing.opengl.*;
import controlP5.*;
import fullscreen.*;
import mappingtools.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.video.*;
import codeanticode.syphon.*;

SyphonServer server;

int numRipples = 1;
int numFlocks = 50;
int numBarriers = 5;

String mode = "PLAY";
Boolean debug = false;
Boolean maskFlag = false;
Boolean gridFlag = false;

color[] pixelBuffer;
PGraphics pg;
PGraphics mask;
PGraphics bMask;
PImage img;

int ys = 25;
int yi = 15;

int diameter = 0;

BezierWarp    bw;
QuadWarp      qw;
Flock         flock;
Minim         minim;
AudioPlayer   player;
AudioMetaData meta;
FFT           fft;

void setup() {
  //new FullScreen(this).enter();
  size(displayWidth,displayHeight,OPENGL);
  frameRate(30);
  smooth();
  
  //noCursor();
  
  pg = createGraphics(width,height,OPENGL);
  mask = createGraphics(width,height,OPENGL);
  bMask = createGraphics(width,height,OPENGL);
  
//  bw = new BezierWarp(this, 10);
//  qw = new QuadWarp(this, 10);
  
  flock = new Flock();
  
  minim = new Minim(this);
  player = minim.loadFile("Go Cart - Loop Mix.mp3",1024);
  meta = player.getMetaData();
  
  
  for (int i = 0; i < numFlocks; i++) {
    int flockType = Math.round(random(0,4));
    flock.addBoid(new Boid(random(width),random(height),flockType));
  }
  
  pg.beginDraw();
  pg.colorMode(HSB,360,100,100);
  pg.background(0);
  pg.endDraw();
  
  mask.beginDraw();
  mask.smooth();
  mask.background(0);
  mask.noStroke();
  for (int w = mask.width; w > 0; w -= 10) {
    mask.fill(255 - w * 255 / mask.width);
    mask.ellipse(mask.width / 2, mask.height / 2, w, w);
  }
  mask.endDraw();
  
  player.loop(); 
  fft = new FFT( player.bufferSize(), player.sampleRate() );
  
  textFont(createFont("Serif", 12));
  
  server = new SyphonServer(this, "Processing Syphon");
}

void draw() {
  background(0);
  
  bMask.beginDraw();
  bMask.smooth();
  flock.bMask(bMask);
  bMask.endDraw();
  
  pg.beginDraw();
  pg.smooth();
  //drawGrid();
  pg.fill(0,30);
  pg.rect(-20, -20, width+40, height+40); //fixed
  //drawFFT();
  flock.run(pg);
  pg.endDraw();
  
  pg.mask(bMask);
  
  if ( mode == "MASK" ) {
    pg.mask(mask);
  }
  
  image(pg,0,0);

//  if ( debug == true ) {
//    drawMeta();
//    image(pg,0,0);
//  } else {
//    qw.render(pg);
//  }
//  
  if (mousePressed) {
    if ( mode == "BARRIER" ) {
      diameter++;
      bMask.beginDraw();
      bMask.fill(0);
      bMask.ellipse(mouseX,mouseY,diameter,diameter);
      bMask.endDraw();
    }
  }
  
  server.sendImage(g);
}

void mousePressed() {
  if( mode == "PLAY" ) {
    cursor();
    flock.pull(mouseX,mouseY);
    for(int i = 0;i < Math.round(random(1,4)) ; i++) {
      flock.addRipple(new Ripple(mouseX*random(0.9,1.1),mouseY*random(0.9,1.1),random(5,20),int(random(180,200))));  
     }
  }
  else if ( mode == "BARRIER" ) {
  }
  else if ( mode == "ADD" ) {
    cursor();
    int flockType = Math.round(random(0,4));
    flock.addBoid(new Boid(mouseX,mouseY,flockType));
  }
  else if ( mode == "DELETE" ) {
    cursor();
    flock.deleteBarrier(mouseX,mouseY);
  }
}
void mouseReleased() {
  if ( mode == "BARRIER" ) {
    flock.addBarrier(new Barrier(mouseX,mouseY,diameter));
    diameter = 0;
  }
}

//void stop() {
//  player.close();  //サウンドデータを終了
//  minim.stop();
//  super.stop();
//}

void keyPressed() {
  if (key == '1') {
      mode = "PLAY";
  } else if (key == '2') {
      mode = "ADD";
  } else if (key == '3') {
      mode = "BARRIER";
  } else if (key == '4') {
      mode = "LOTUS";
  } else if (key == '5') {
      mode = "AJUST";
  } else if (key == '6') {
      mode = "MASK";
  } else if (key == '7') {
      mode = "DELETE";
  }
  if (key == ENTER) {
    if (debug == true) {
      debug = false;
    } else {
      debug = true;
    }
  }
}
void debugMode() {
}

void drawGrid() {
  int gridSize = 10;
  pg.stroke(127, 127);
  pg.strokeWeight(1);
  for (int x = 0; x < width; x+=gridSize) {
    pg.line(x, 0, x, height);
  }
  for (int y = 0; y < height; y+=gridSize) {
    pg.line(0, y, width, y);
  }
}

void drawFFT() {
  pg.stroke(255);
  fft.forward( player.mix );
  for(int i = 0; i < fft.specSize(); i++)
  {
    pg.line( i, height, i, height - fft.getBand(i)*8 );
  }
}

void drawMeta() {
  int y = ys;
  text("File Name: " + meta.fileName(), 5, y);
  text("Length (in milliseconds): " + meta.length(), 5, y+=yi);
  text("Title: " + meta.title(), 5, y+=yi);
  text("Author: " + meta.author(), 5, y+=yi); 
  text("Album: " + meta.album(), 5, y+=yi);
  text("Date: " + meta.date(), 5, y+=yi);
  text("Comment: " + meta.comment(), 5, y+=yi);
  text("Track: " + meta.track(), 5, y+=yi);
  text("Genre: " + meta.genre(), 5, y+=yi);
  text("Copyright: " + meta.copyright(), 5, y+=yi);
  text("Disc: " + meta.disc(), 5, y+=yi);
  text("Composer: " + meta.composer(), 5, y+=yi);
  text("Orchestra: " + meta.orchestra(), 5, y+=yi);
  text("Publisher: " + meta.publisher(), 5, y+=yi);
  text("Encoded: " + meta.encoded(), 5, y+=yi);
}
