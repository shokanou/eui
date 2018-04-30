import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import beads.*;

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

AudioContext ac;
SamplePlayer song;
SamplePlayer noise;
Gain sampleGain;
Gain noiseGain;
Glide gainValue;
Glide rateValue;
Glide noiseValue;

int thGain;

ArrayList<ArrayList<AccelerationSample>> dataList;
ArrayList<Integer> dataId;
MyLock myLock;
ArrayList<AccelerationSample> inputBuffer;


float plottedMs = 15000.0;
float accMult = 2.0;

float totalCurrAbs = 0;
int N = 0;

int counter = 0;
long oldAbs = 0;
long oldTimes = 0;



void setup() {
  oscP5 = new OscP5(this, 7018);
  
  size(1200, 600,P3D);
  frameRate(30);

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");

  myLock = new MyLock();
  inputBuffer = new ArrayList<AccelerationSample>();
  
  dataList = new ArrayList<ArrayList<AccelerationSample>>();
  dataId = new ArrayList<Integer>();

  
  // UPLOADING SONG FILE
  ac = new AudioContext();
  try {
    println("tried to upload");
    song = new SamplePlayer(ac, new Sample("/Users/VilleVartiainen/Documents/lipasto/emergent/eui/accelerationSonificationCopy/toto.mp3"));
    //noise = new SamplePlayer(ac, new Sample("/Users/VilleVartiainen/Documents/lipasto/emergent/eui/accelerationSonificationCopy/toto.mp3"));
    println("Song uploaded");
  }
  catch(Exception e)
  {
     // if there is an error, show an error message
     println("Exception while attempting to load sample.");
     e.printStackTrace();
     exit();
   }
   // FOR MUSIC CONTROL
   // play the sample multiple times
   println("Song uploaded - after try");
   song.setKillOnEnd(false);
   //noise.setKillOnEnd(false);
   
   thGain = 30;
   // initialize our rateValue Glide object
   rateValue = new Glide(ac, 0.5, thGain);
   song.setRate(rateValue); 
   // creating a gain that will control the volume of our sample player
   gainValue = new Glide(ac, 0.0, thGain);
   sampleGain = new Gain(ac, 1, gainValue);
   sampleGain.addInput(song);
   
   /*
   // creating a gain that will control the volume of noise
   noiseValue = new Glide(ac, 0.0, thGain);
   noiseGain = new Gain(ac, 1, noiseValue);
   noiseGain.addInput(noise);
   */
   // connect Gains to the AudioContext
   ac.out.addInput(sampleGain);
   //ac.out.addInput(noiseGain);
   ac.start(); // begin audio processing
   println("music stuff initialized");
   song.setPosition(000);
   gainValue.setValue(30);
   song.start();
   println("song started");
   
   
  initializeReceiving();
}



void draw() {
  background(0);
  colorMode(HSB, 100);
  strokeWeight(2);
  
  int tSize = 32;
  textSize(tSize);
  text("X", 10, (height * 0.0) + tSize);
  text("Y", 10, (height * 0.25) + tSize);
  text("Z", 10, (height * 0.5) + tSize);
  text("abs", 10, (height * 0.75) + tSize);
}



void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

void startPlaying()
{
  song.start();
  //noise.start();
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  //Receiving only one per x messages; not to be stuck
  counter++;
  if (counter > 5)
  {
    counter = 0;
    if (message.checkAddrPattern("/fsensync/acc") == true)
    {
      int appId = message.get(0).intValue();
      String tags = message.get(1).stringValue();
      int packetNumber = message.get(2).intValue();
      int timeStamp = message.get(3).intValue();
      float x = message.get(4).floatValue();
      float y = message.get(5).floatValue();
      float z = message.get(6).floatValue();
  
      myLock.lock();
      AccelerationSample curr = new AccelerationSample(x, y, z, appId, timeStamp);
          
      boolean changed = false;
      
      // Compare curr.time with oldTimes, if difference is greater than 0.5 seconds, start new period
      if (curr.time - oldTimes > 1000) {
        oldTimes = curr.time;
        changed = true;
      }

      if (changed) {
        setThatThingy(curr.id, curr.time, totalCurrAbs, N);
        totalCurrAbs = 0;
        N=0;
      }
      
      //get total acceleration for current data by adding the abs acc of each AccelerationSample together
      float currAbs = (float)Math.sqrt((curr.x * curr.x) + (curr.y * curr.y) + (curr.z * curr.z)); 
      totalCurrAbs += currAbs;
      N++;
      
      myLock.unlock();
      
      return;
    }
  
    {
      println("got other message: " + message.addrPattern());
      return;
    }
  }
}



void setThatThingy(int id, long t, float ta, int N) {
  float a = totalCurrAbs / N;
  println("setThatThingy time: " + t + " acceleration: " + a + " total: " + ta + " #samples: " + N);
  
  // normalize
  float bla = a/40 + 0.2;
  bla = int(bla*100);
  bla = bla/100;
  if(id == 0)
    gainValue.setValue(bla);
  else if (id == 1) 
    rateValue.setValue(bla);
  else 
    noiseValue.setValue(1-bla);
  println("setValue" + bla);
}
