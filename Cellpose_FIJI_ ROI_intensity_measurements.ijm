// Cellpose ROI Intensity Data with erosion/dilation
// Author: Antonio Villanueva 
// Email: villanueva.a@northeastern.edu 
// 3/10/2021
// ImageJ FIJI version 1.8
// This code loops through a master directory containing folders of images/images in order to obtain intensity data. Each folder in the master directory must have a .txt ROI list (from cellpose) with the respective .TIF fluoresence image(s).
// The cellpose mask is converted to an Overlay and saved as a TIF. The user will be given prompts to remove cells and edit ROIs as desired for the Overlay. The Overlay will then be used to calculate intensity data for each TIF in the folder.
// Intensity data are saved in the same folder as the master directory. 
// Edit the line of code at 'CHANGE MEASUREMENTS HERE' to change what type of measurements are stored in the CSVs.

// IMPORTANT: For macro to function, a folder must contain DAPI tif saved as "DAPI.tif"(ONLY ONE PER FOLDER ENDING IN DAPI.tif), cellpose ROI txt file (imported from cellpose), and tif images of channels of interest saved as "{channel}.tif". 
//            example of naming convention:
//            	Folder name: "Animal 1"
//            	Inside folder: "DAPI.tif","cellpose_outlines.txt","mCherry.tif", "mAG.tif","Edu.tif"...


// NOTE: THIS CODE IS NOT USER FRIENDLY. While the program is running, do not interfere with windows unless prompted to do so. 

// Template for Batch Processing from https://imagej.nih.gov/ij/macros/BatchProcessFolders.txt

// IMPORTANT: REQUIRES CODE DEVELOPED BY VINI SALAZAR AND CARSEN STRINGER TO CONVERT CELLPOSE ROIS TO IMAGEJ.
//            CODE MUST BE SAVED AS "CP_FIJI_converter.py" IN DIRECTORY "C:\Fiji\Fiji.app\macros" 
//            Code can be downloaded from https://github.com/MouseLand/cellpose/blob/master/imagej_roi_converter.py
   
// Intialize directories and prcoess all files in folder/subfolders
   requires("1.33s"); 
   dir = getDirectory("Choose a Directory ");
   parent = File.getParent(dir);
   intensitydata = dir+File.separator+"intensity_data"+File.separator;
   File.makeDirectory(intensitydata);
   setBatchMode(false);
   count = 0;
   countFiles(dir);
   n = 0;
   processFiles(dir);

   
   function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
  }

   function processFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              processFiles(""+dir+list[i]);
          else {
              showProgress(n++, count);
              path = dir+list[i];
              GenerateOverlayIntData(path);
             
          }
      }
  }

   function GenerateOverlayIntData(path) {

       // Open DAPI image that what used for Cellpose
          if (endsWith(path, "DAPI.tif") == true) {
            open(path);
            CPMask = getTitle();
            selectWindow(CPMask);

	   // Prompt user to remove unwanted cells when generating Overlay
		  beep();
		  waitForUser("Select the .txt file containing the Cellpose generated masks that corresponds to the DAPI.tif. Press 'Ok' to proceed.");

	   // Generate Overlay using CP_FIJI_converter.py and erode/dilate pixels
		  runMacro('CP_FIJI_converter.py');

       // Open erosion/dilation dialog 
		  Dialog.create("Erode/Dilate ROIs");
		  Dialog.addNumber("Erode/Dilate pixels (erode is negative)", 0);
          Dialog.show();
          pix = Dialog.getNumber();
		  
		  for (n=0;n<roiManager("count");n++){
            roiManager("select", n);
         // Erode perimeter by n pixels 
          	run("Enlarge...", "enlarge=" +  pix + " pixel");
          	roiManager("update");
          	
           }	
		// Prompt user to edit ROIs in the Overlay 
		   beep();
		   
		// run("From ROI Manager");
		   waitForUser("Edit ROIs and ROI manager. Press 'Ok' to save as TIFF, collect intensity data, and proceed to next image.");

		// Save Overlay as TIFF in folder with mask
		   if (pix > 0) {
	         ED = "_Dilated_" + pix + "_pixel";
           }

		   if (pix < 0) {
				ED = "_Eroded_" + pix + "_pixel";
		   }
		   if (pix == 0) {
				ED = "_Original";
		   }
		   saveAs("tiff", substring(path, 0, lengthOf(path) - 4) + ED + "_Cellpose_Overlay.tif");
		   close();
		
		// Collect intensity data for each TIFF in folder and save results as CSV in "intensity_data" folder NOTE: Exlcudes DAPI TIFF (remove "& (endsWith(list[i], "DAPI.tif") == false)" to include DAPI)
		   data = intensitydata+ED+File.separator;
		   File.makeDirectory(data);  
		   for (i=0; i<list.length; i++) {
		      if (endsWith(list[i], ".tif") == true & (endsWith(list[i], "_Cellpose_Overlay.tif") == false) & (endsWith(list[i], "DAPI.tif") == false)) { // REMOVE "& (endsWith(list[i], "DAPI.tif") == false)" to include DAPI
           	     open(dir+list[i]);
           		 T = getTitle();
				 selectWindow(T);
           		 run("From ROI Manager");
           		 run("Set Measurements...", "area mean min integrated redirect=None decimal=3"); // CHANGE MEASUREMENTS HERE 
           	        for (n=0;n<roiManager("count");n++){
					   roiManager("select", n); 
					   run("Measure");
					   roiManager("Deselect");
						
						}
				  roiManager("Show All");
				  selectWindow(T);
				  saveAs("Results",data+substring(T, 0, lengthOf(T) - 4)+".csv");
				  selectWindow("Results");
				  run("Clear Results");
		    	  selectWindow(T);
			      close();
						
					}
				}

				roiManager("reset");
				selectWindow("ROI Manager");
				run("Close");
				selectWindow("Results");
				run("Close");
	
      }
   }

// Notify user program is complete
   beep();
   waitForUser("Complete");

// CSVs were manually loaded and organized on excel 
// Positive and negative cells were determined by dividing each cell's mean pixel value by the maximum mean pixel value across all cells. Any resulting quotient greater than 0.05 was labeled postive for 
// mAG and greater than 0.04 for mCherry. 

