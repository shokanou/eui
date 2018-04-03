
class MyLock {

  int lockCount = 0;
  
  synchronized void lock()
  {
    while (lockCount > 0)
    {
      try
      {
      wait();
      }
      catch (InterruptedException ex) {}
    }
    lockCount++;
  }
  
  synchronized void unlock()
  {
    lockCount--;
    notifyAll();
  }
  
}
