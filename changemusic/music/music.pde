import ddf.minim.*;

Minim minim;

AudioPlayer player;

  String song1 = "1.mp3";
  String song2 = "2.mp3";
  String song3 = "3.mp3";
  String song = "1.mp3"; //current

 

void setup() {

  size(512,200);

   

  // Minim jiazai wenjian 

  minim = new Minim(this);


  // dutu de fangshi


  player = minim.loadFile(song);

}

 

 

void
draw() {

  background(0);

  stroke(255);

   

  // boxing 

  // 由 left.get() 和 right.get() 返回的值将是-1 和 1 之间，

  // 所以需要映射到合适的大小

  // 如果是MONO单声道文件，left.get() 和 right.get() 将返回相同的值

  for(int i=0; i<player.bufferSize()-1; i++) {

    float x1 = map( i, 0, player.bufferSize(), 0, width );

    float x2 = map( i+1, 0, player.bufferSize(), 0, width);

    line( x1, 50 + player.left.get(i)*50, x2, 50 + player.left.get(i+1)*50);

    line( x2, 150 + player.right.get(i)*50, x2, 150 + player.right.get(i+1)*50);

  }

  // xian xianshi weizhi

  float posx = map(player.position(), 0, player.length(), 0, width);

  stroke(0,200,0);

  line(posx, 0, posx, height);

   

  if
( player.isPlaying() )

  {

     text("Press s to pause playback.", 10, 20
);

  }

  else

  {

    text("Press s to start playback.", 10, 20
);

  }

}

 

 

void keyPressed()

{

  if((key == 'S') || (key == 's') ) {
    if(player.isPlaying())
      {
        player.pause();
      }
      else{
        player.play();
      }
    };
    
   if(key == '1'){
        if(song == song1)
          ; 
        else{
        song = song1;
        player.pause();
        player = minim.loadFile(song);
        player.play();
        }
  };
   
   if(key == '2'){
      if(song == song2)
            ;
     
     else{
      song = song2;
      player.pause();
      player = minim.loadFile(song);
      player.play();
     }
    };
    
    if(key == '3'){
      if(song == song3)
            ;
      else{
      song = song3;
      player.pause();
      player = minim.loadFile(song);
      player.play();
      }
    };
  

  // 如果播放到文件末尾

  // 我们使他再播一遍

    if ( player.position() == player.length() ) {

    player.rewind();

    player.play();

  };

}
