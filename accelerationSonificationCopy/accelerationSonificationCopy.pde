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
int counter 
long oldAbs = 0;
long oldTimes = 0;
List<Float> currAbsValues = new ArrayList<Float>();

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

  myLock.lock();
  for (int i = 0; i < inputBuffer.size(); i++)
  {
    AccelerationSample sample = inputBuffer.get(i);
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == sample.id)
      {
        found = true;
        ArrayList<AccelerationSample> data = dataList.get(listInd);
        data.add(sample);
      }
    }
    if (!found)
    {
      ArrayList<AccelerationSample> data = new ArrayList<AccelerationSample>();
      data.add(sample);
      dataId.add(sample.id);
      dataList.add(data);
    }
  }
  inputBuffer.clear();
  myLock.unlock();

  // Sorting all data lists
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<AccelerationSample> data = dataList.get(listInd);
  
    Collections.sort(data, new Comparator<AccelerationSample>() {
      public int compare(AccelerationSample acc1, AccelerationSample acc2)
      {
        return (int)(acc1.time - acc2.time);
      }
    });
  }
  
  // Finding the max timestamp
  long maxTime = 0;
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<AccelerationSample> data = dataList.get(listInd);
    if (data.size() > 1 && maxTime < data.get(data.size()-1).time)
    {
      maxTime = data.get(data.size()-1).time;
    }
  }
  
  // Removing old data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<AccelerationSample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      for (int i = data.size()-1; i >= 0; i--)
      {
        if (data.get(i).time < maxTime - (long)plottedMs)
        {
          data.remove(i);
        }
      }
    }
  }
  
  // Plotting the data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<AccelerationSample> data = dataList.get(listInd);
    if (data.size() > 1)
    { 
      stroke((15*listInd) % 100, 100, 100);
      
      long xStart = maxTime - (maxTime % 5000) + 5000;
      
      for (int i = 1; i < data.size(); i++)
      {
        AccelerationSample acc0 = data.get(i-1);
        AccelerationSample acc1 = data.get(i);
        // Minim create sound
        // Normalize abs1 to range of 0-10
//          int norm  = int(abs1 / 70 * 10); 
//          println(norm);
        
//        hack = hack + 1;
//        hack2 = hack2+1;
//        println(acc1.x);
        
//        if(hack == 100){
          //out.playNote( 0.0, 0.2, hack2*0.1);
//            out.playNote(norm*10);
//            out.playNote( 0.000, 1, new SteadyGrainInstrument( abs1*10, 10, 1.0, 0.15 ) );
//          out.playNote(0, 0.2, 100+acc1.x);
//          hack = 0;
//        }
//          if(hack2 == 10000)
//          {
//            hack2 = 0;
//          }
        // Minim


        if (acc1.time - acc0.time < 1000)
        {
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.x * accMult) + (height * 0.125), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.x * accMult) + (height * 0.125));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.y * accMult) + (height * 0.375), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.y * accMult) + (height * 0.375));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.z * accMult) + (height * 0.625), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.z * accMult) + (height * 0.625));
          
          float abs0 = (float)Math.sqrt((acc0.x * acc0.x) + (acc0.y * acc0.y) + (acc0.z * acc0.z));
          float abs1 = (float)Math.sqrt((acc1.x * acc1.x) + (acc1.y * acc1.y) + (acc1.z * acc1.z));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                ((-abs0 + 10.0) * accMult) + (height * 0.875), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                ((-abs1 + 10.0) * accMult) + (height * 0.875));
        }
      }
    }
  }
  // Get half second increments of data
  // Save total(or avg?) absolute acceleration of current dataList
  //    currPeriodTotal += abs;
  // Save maxTime of dataList
  // Compare maxTime with previous maxTime
  // -> if diff <half second, add abs acceleration to period total (or avg)
  // if greater, save period
  
  // If two periods saved (if prevPeriodTotal > 0)
  // -> Compare period total / avg acceleration
  // -> -> if greater, volume up, else volume down
  // current period becomes old period, begin new period
  
  // ------------
  // Okay. We've oldTimes for the previous timestamp when we started a new period
  // We also have totalCurrAbs for total current absolute acceleration and oldAbs for the totalCurrAbs of the previous period
  // We also have boolean changed to track whether we've started a new period
  // If the diff between oldTimes and curr.time (data.get(i).time) > 0.5 seconds
  //    - oldAbs = totalCurrAbs;
  //    - oldTimes = curr.time;
  //    - totalCurrAbs = 0; // NOT here yet!
  //    - changed = true;

  
  // if(changed){
     // Compare oldAbs and currTotalAbs to see which one is bigger
     // if totalCurrAbs times two, so volume will go up as long as totalCurrAbs is at least half of oldAbs (otherwise keeping volume up would be hard)
     //if (totalCurrAbs*2 > oldAbs)
     //  volumeUp();
     //else volumeDown();
     //totalCurrAbs = 0;
  //}
  
  
  //long totalCurrAbs = 0;
  // Set changed to false.
  //boolean changed = false;
  /*
  // Loop through all acceleration samples
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<AccelerationSample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      // Loop through data in acceleration samples
      for (int i = data.size()-1; i >= 0; i--)
      {
        boolean changed = false;
        AccelerationSample curr = data.get(i);
        // Compare curr.time with oldTimes, if difference is greater than 0.5 seconds, start new period
        if (curr.time - oldTimes > 500) {
          //oldAbs = totalCurrAbs;
          oldTimes = curr.time;
          //totalCurrAbs = 0;
          changed = true;
        }
        
        // If new period was started above
        if(changed){
        // Compare oldAbs and currTotalAbs to see which one is bigger
        // if totalCurrAbs times two, so volume will go up as long as totalCurrAbs is at least half of oldAbs (otherwise keeping volume up would be hard)
          if (totalCurrAbs > oldAbs * 1.5)
            volumeUp(curr.time, totalCurrAbs, oldAbs);
          else volumeDown(curr.time, totalCurrAbs, oldAbs);
          oldAbs = totalCurrAbs;
          totalCurrAbs = 0;
        }
        
        // TODO: After comparing timestamps, seing if period has changed, do what?
        //get total acceleration for current data by adding the abs acc of each AccelerationSample together
        float currAbs = (float)Math.sqrt((curr.x * curr.x) + (curr.y * curr.y) + (curr.z * curr.z)); 
        totalCurrAbs += currAbs;
      }
    }
  }*/
  
  
  // half second increment end
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
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
    //inputBuffer.add(curr);
    
        boolean changed = false;
        // Compare curr.time with oldTimes, if difference is greater than 0.5 seconds, start new period
        if (curr.time - oldTimes > 1000) {
          //oldAbs = totalCurrAbs;
          oldTimes = curr.time;
          //totalCurrAbs = 0;
          changed = true;
        }

        if (changed) {
          for (float currAbsValue : currAbsValues) {
            totalCurrAbs += currAbsValue;
          }
          float avgCurrAbs = totalCurrAbs / currAbsValues.size();
          volumeAvg(curr.time, avgCurrAbs);
          totalCurrAbs = 0;
        }

        /*
        // If new period was started above
        if(changed){
        // Compare oldAbs and currTotalAbs to see which one is bigger
        // if totalCurrAbs times two, so volume will go up as long as totalCurrAbs is at least half of oldAbs (otherwise keeping volume up would be hard)
          if (totalCurrAbs > oldAbs * 1.2)
            volumeUp(curr.time, totalCurrAbs, oldAbs);
          else if (totalCurrAbs < oldAbs*0.8)
            volumeDown(curr.time, totalCurrAbs, oldAbs);
          else volumeNeutral(curr.time, totalCurrAbs, oldAbs);
          oldAbs = totalCurrAbs;
          totalCurrAbs = 0;
        }
        */
        // TODO: After comparing timestamps, seing if period has changed, do what?
        //get total acceleration for current data by adding the abs acc of each AccelerationSample together
        float currAbs = (float)Math.sqrt((curr.x * curr.x) + (curr.y * curr.y) + (curr.z * curr.z)); 
        totalCurrAbs += currAbs;
=======
        //totalCurrAbs += currAbs;
        // put currAbs into an array
        currAbsValues.add(currAbs);
>>>>>>> 35aa4e9a11296fa0ddf1109cec3a65621a474dde
    
    myLock.unlock();
    
    return;
  }

  {
    println("got other message: " + message.addrPattern());
    return;
  }
}


void volumeAvg(long t, float a) {
  println("Volume Neutral: time: " + t + " acceleration: " + a);
}
