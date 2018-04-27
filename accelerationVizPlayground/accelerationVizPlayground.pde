import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

ArrayList<ArrayList<AccelerationSample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;
ArrayList<AccelerationSample> inputBuffer;

ArrayList<AccelerationSample> lastInput;

float plottedMs = 15000.0;
float accMult = 2.0;

void setup() {
  size(1200, 800,P3D);
  frameRate(30);
  
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
  
  // Checking if the data comes from a known id or new one
  // WTF is data list
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
  
  
  // Removing old data => ???
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
       
        if (acc1.time - acc0.time < 1000)
        {
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.x * accMult) + (height * 0.125), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.x * accMult) + (height * 0.125));
                
           line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.intx * accMult) + (height * 0.375), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.intx * accMult) + (height * 0.375));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.MAx * accMult) + (height * 0.625), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.MAx * accMult) + (height * 0.625));
          
          /*line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.y * accMult) + (height * 0.375), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.y * accMult) + (height * 0.375));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.z * accMult) + (height * 0.625), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.z * accMult) + (height * 0.625));*/
          
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
  
}


/* 
RECEIVING MESSAGES
*/

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
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == appId)
      {
        found = true;
        float MAx = 0.7*x + lastInput.get(listInd).MAx * 0.3;
        float intx = lastInput.get(listInd).intx;
        print(MAx, ",", intx);
        AccelerationSample sample = new AccelerationSample(x, y, z, MAx, intx, appId, timeStamp);
        ArrayList<AccelerationSample> data = dataList.get(listInd);
        data.add(sample);
        lastInput.set(listInd, sample);
      }
    }
    if (!found)
    {
      AccelerationSample sample = new AccelerationSample(x, y, z, x, x, appId, timeStamp);
      ArrayList<AccelerationSample> data = new ArrayList<AccelerationSample>();
      data.add(sample);
      lastInput.add(sample);
      dataId.add(appId);
      dataList.add(data);
    }
    
    myLock.unlock();
    
    return;
  }

  {
    println("got other message: " + message.addrPattern());
    return;
  }
}
