import ddf.minim.*;
import ddf.minim.ugens.*;
 
Minim       minim;
AudioOutput out;
Oscil       wave;
 
void setup()
{
  size(512, 200, P3D);
 
  minim = new Minim(this);
 
  // use the getLineOut method of the Minim object to get an AudioOutput object
  out = minim.getLineOut();
 
  // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
//  wave = new Oscil( 440, 0.5f, Waves.SINE );
  // patch the Oscil to the output
//  wave.patch( out );
}
 
void draw()
{
/*
  background(0);
  stroke(255);
  strokeWeight(1);
 
  // draw the waveform of the output
  for(int i = 0; i < out.bufferSize() - 1; i++)
  {
    line( i, 50  - out.left.get(i)*50,  i+1, 50  - out.left.get(i+1)*50 );
    line( i, 150 - out.right.get(i)*50, i+1, 150 - out.right.get(i+1)*50 );
  }
 
  // draw the waveform we are using in the oscillator
  stroke( 128, 0, 0 );
  strokeWeight(4);
  for( int i = 0; i < width-1; ++i )
  {
    point( i, height/2 - (height*0.49) * wave.getWaveform().value( (float)i / width ) );
  }*/
}
 
void mouseMoved()
{
  // usually when setting the amplitude and frequency of an Oscil
  // you will want to patch something to the amplitude and frequency inputs
  // but this is a quick and easy way to turn the screen into
  // an x-y control for them.
 
 out.playNote( 0.0, 0.2, mouseX);
 //out.playNote( 0.000, 1, new SteadyGrainInstrument( mouseX, mouseY, 1.0, 0.15 ) );
 /*
  float amp = map( mouseY, 0, height, 1, 0 );
  wave.setAmplitude( amp );
 
  float freq = map( mouseX, 0, width, 0, 880 );
  wave.setFrequency( freq );
  */
}

 /*
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

     case '6':
      wave.setWaveform( Waves.QUARTERPULSE );
      break;
 
    default: break; 
  }
}*/

// Every instrument must implement the Instrument interface so 
// playNote() can call the instrument's methods.
class SteadyGrainInstrument implements Instrument
{
  // create all variables that must be used throughout the class
  GranulateSteady chopper;
  
  // constructor for this instrument
  SteadyGrainInstrument( float frequency, float amplitude, float period, float percentOn )
  { 
    // create new instances of any UGen objects as necessary
    // Need the triangle tone to chop up.
    Oscil toneOsc = new Oscil( frequency, amplitude, Waves.TRIANGLE );
    // need the GranulateSteady envelope
    chopper = new GranulateSteady( period*percentOn, period*( 1 - percentOn ), 0.0025 );
    
    // patch everything together up to the final output
    // the tone just goes into the chopper
    toneOsc.patch( chopper );
  }
  
  // every instrument must have a noteOn( float ) method
  void noteOn( float dur )
  {
    chopper.patch( out );
  }
  
  // every instrument must have a noteOff() method
  void noteOff()
  {
    chopper.unpatch( out );
  }
}
