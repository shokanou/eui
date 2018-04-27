import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

// Minim
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim       minim;
AudioOutput out;
// Minim

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

ArrayList<ArrayList<AccelerationSample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;
ArrayList<AccelerationSample> inputBuffer;

float plottedMs = 15000.0;
float accMult = 2.0;

//int hack = 0;
//int hack2 = 0;
float totalCurrAbs = 0;
int N = 0;

int counter = 0;
long oldAbs = 0;
long oldTimes = 0;

void setup() {
  size(1200, 600,P3D);
  frameRate(30);
  
  // Minim init
  minim = new Minim(this);
 
  // use the getLineOut method of the Minim object to get an AudioOutput object
  out = minim.getLineOut();
  // Minim init end

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");

  myLock = new MyLock();
  inputBuffer = new ArrayList<AccelerationSample>();
  
  dataList = new ArrayList<ArrayList<AccelerationSample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 7018);
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

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  counter++;
  if (counter > 100)
  {
    println("message received");
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
        float avgCurrAbs = totalCurrAbs / N;
        volumeAvg(curr.time, avgCurrAbs);
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


void volumeAvg(long t, float a) {
  println("Volume Neutral: time: " + t + " acceleration: " + a);
}
