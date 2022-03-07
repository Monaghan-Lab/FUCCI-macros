// Sacled ROI column amputation data
// Antonio Villanueva 
// Email: villanueva.a@northeastern.edu
// 3/4/2021
// ImageJ FIJI version 1.8
// This code segments an amputated smaple into the desired number of proximal and distal sections. Intensity data is collected from these ROIs.
// Edit the line of code at 'CHANGE MEASUREMENTS HERE' to change what type of measurements are stored in the CSVs. 
// NOTE: THIS CODE IS NOT USER FRIENDLY. While the program is running, do not interfere with windows unless prompted to do so. 

// Requires empty ROI manager and Results table with desired image already opened
// Press 'esc' to cancel program at anytime
// Close windows to reset 

// Get directory of opened image 
   requires("1.33s"); 
   dir = getDirectory("image");
   setTool("freehand");
   waitForUser("Outline the sample and cut out the background using the freehand tool. Press 'OK' when finished.");
   setBackgroundColor(0, 0, 0);
   run("Clear Outside");
   run("Select None");

// Create mask of entire sample
   T = getTitle();
   run("Duplicate...", " ");
   T2 = getTitle();

// Adjust accuracy of mask here 
   selectWindow(T2);
   run("8-bit");
   var min, max;
   getMinAndMax(min, max);
   setAutoThreshold("Default dark");
   run("Threshold...");
   setThreshold(min + 1, max);
   setOption("BlackBackground", true);
   run("Convert to Mask");
   run("Close");
   run("Dilate");
   run("Fill Holes");
   run("Erode");
   run("Analyze Particles...", "add");
   roiManager("Select", 0);
   run("Make Inverse");

// Manually ask user to set scale
   waitForUser("Set Scale of image. Copy the scale in pixels/unit when prompted after setting scale.");
   run("Set Scale...");
   Dialog.create("What is the scale?");
   Dialog.addNumber("Pixels/unit:", 1);
   Dialog.show();
   Scale = Dialog.getNumber()

// Select amputation plane
   setTool("multipoint");
   waitForUser("Select center of amputation plane with multipoint tool. Press 'OK' when finished.");
   run("Measure");
   x = getResult("X", nResults - 1);
   y = getResult("Y", nResults - 1);
   xs = x * Scale
   run("Clear Results");
// selectWindow("Results");
// run("Close");

// Determine number of boxes 
   title = getTitle;
   width = getWidth;
   height = getHeight;

// Create Box Dialog
   Dialog.create("Amp plane Box editor");
   Dialog.addNumber("Proximal Boxes:", 1);
   Dialog.addNumber("Distal Boxes:", 1);
   Dialog.addNumber("Box Width (units)", 10);
   Dialog.show();
   ProxBox = Dialog.getNumber();
   DistBox = Dialog.getNumber();
   Boxwidth = Dialog.getNumber();
   Boxwidth = Boxwidth * Scale

// Set measurements and select only boxes capturing ROI
// Make proximal boxes 
   run("Set Measurements...", "area mean standard min bounding integrated kurtosis redirect=None decimal=3");
   for (n=0;n<ProxBox;n++){
      makeRectangle(xs - ((n+1) * Boxwidth), 0, Boxwidth, height); 
      run("Measure");
      int = getResult("IntDen", nResults - 1);
	  if (int>0) {
	    roiManager("Add");
	  }
	  run("Clear Results");
   
   }
    
// Make distal boxes
   for (n=0;n<DistBox;n++){
       makeRectangle(xs + (n * Boxwidth), 0, Boxwidth, height); 
       run("Measure");
	   int = getResult("IntDen", nResults - 1);
      if (int>0) {
	     roiManager("Add");
	     }
	   run("Clear Results");
   }
   run("Select None");
    
// Merge boxes with sample mask
   len = roiManager("count")
   for (i=1;i<len;i++){
      roiManager("Select", newArray(0,i));
      roiManager("AND");
      roiManager("Add");
   }

   for (i=0;i<len - 1;i++){
      roiManager("Select", 0);
      roiManager("Delete");
   }

// Overlay to original image
   selectWindow(T);
   run("From ROI Manager");
   selectWindow(T2);
   close();
   selectWindow(T);

// Collect data
   for (n=0;n<roiManager("count");n++){
      roiManager("select", n); 
      run("Measure");
      roiManager("Deselect");
   
   }

   roiManager("Show All without labels");
   roiManager("Show All with labels");
    
// Notify user
   beep();
   waitForUser("Complete. Press 'Ok' to save overlay and data in same folder.");


// Save data
   selectWindow(T);
   saveAs("tiff", dir + substring(T, 0, lengthOf(T) - 4) + "_Overlay_AmpPlane_x=" + x + ".tif");
   T = getTitle();
	
   selectWindow("Results");
   saveAs("Results", dir + substring(T, 0, lengthOf(T) - 4) + "_AmpPlane_x=" + x + ".csv");

// Close all
   selectWindow(T);
   close();
   roiManager("Delete");
   selectWindow("ROI Manager");
   run("Close");
   selectWindow("Results");
   run("Close");
    
// Intensity of each ROI column is calculated by dividing the raw integrated density by the area of the ROI.





    