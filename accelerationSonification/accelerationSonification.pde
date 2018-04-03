import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

// Minim stuff
import ddf.minim.*;
import ddf.minim.ugens.*;
 
Minim       minim;
AudioOutput out;
Oscil       wave;
// Minim stuff

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

ArrayList<ArrayList<AccelerationSample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;

float plottedMs = 15000.0;
float accMult = 2.0;

void setup() {
  size(1200, 800);
  frameRate(30);

  myLock = new MyLock();
  dataList = new ArrayList<ArrayList<AccelerationSample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 8000);
  initializeReceiving();
  
  // Minim initialize
  minim = new Minim(this);
 
  // use the getLineOut method of the Minim object to get an AudioOutput object
  out = minim.getLineOut();
 
  // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
  wave = new Oscil( 440, 0.5f, Waves.SINE );
  // patch the Oscil to the output
  wave.patch( out );
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

          // Instead of setting these at mouseMoved() like in minimtest, we do it here
          // Obs! I think acc0 refers to the previous value the accelerometer gave us
          // and acc1 to the most recent ones - there's two for drawing lines between them
          // abs0 and abs1 seem to be the acceleration
          //
          // Currently we take the value x of acc0 and acc1 and use those for amplitude and frequency.
          // The X is multiplied by an arbitrary number 6, because otherwise the sound would be inaudible
          //
          // TODO: Come up with something more sensible / robust here
          // Also try to extend the sound / smoothen transition to get rid of the tut tut tut
          
          float amp = map( acc1.y * 6, 0, height, 1, 0 );
          wave.setAmplitude( amp );
         
          float freq = map( abs1 * 6, 0, width, 0, 4080 );
          wave.setFrequency( freq );
          
          // Minim hackiness ends
        }
      }
    }
  
  }
  
  myLock.unlock();
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
    long timeStamp = message.get(3).longValue();
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
        ArrayList<AccelerationSample> data = dataList.get(listInd);
        data.add(new AccelerationSample(x, y, z, appId, timeStamp));
      }
    }
    if (!found)
    {
      ArrayList<AccelerationSample> data = new ArrayList<AccelerationSample>();
      data.add(new AccelerationSample(x, y, z, appId, timeStamp));
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

// This is for changing the sound like what minim provides in the example
void keyPressed()
{ 
  switch( key )
  {
    case '1': 
      wave.setWaveform( Waves.SINE );
      break;
 
    case '2':
      wave.setWaveform( Waves.TRIANGLE );
      break;
 
    case '3':
      wave.setWaveform( Waves.SAW );
      break;
 
    case '4':
      wave.setWaveform( Waves.SQUARE );
      break;
 
    case '5':
      wave.setWaveform( Waves.QUARTERPULSE );
      break;
 
    default: break; 
  }
}
