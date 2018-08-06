//+------------------------------------------------------------------
//|                                       originaly Written by IgorAD
//|                                            this version by mladen
//+------------------------------------------------------------------
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_minimum -2
#property indicator_maximum  2
#property indicator_buffers  2
#property indicator_color1  clrLime
#property indicator_color2  clrRed
#property indicator_width1  3
#property indicator_width2  3

//
//
//
//
//

extern ENUM_TIMEFRAMES    TimeFrame        = PERIOD_CURRENT;
extern int                RsiPeriod        = 14;
extern ENUM_APPLIED_PRICE RsiPrice         = PRICE_CLOSE;
extern bool               alertsOn         = false;
extern bool               alertsOnCurrent  = true;
extern bool               alertsMessage    = true;
extern bool               alertsSound      = false;
extern bool               alertsNotify     = false;
extern bool               alertsEmail      = false;
extern string             soundFile        = "alert2.wav";
extern bool               ShowArrows       = false;
extern string             arrowsIdentifier = "rf Arrows";
extern double             arrowsUpperGap   = 0.5;
extern double             arrowsLowerGap   = 0.5;
extern color              arrowsUpColor    = LimeGreen;
extern color              arrowsDnColor    = Red;
extern color              arrowsUpCode     = 241;
extern color              arrowsDnCode     = 242;


//
//
//
//
//

double UpBuffer[];
double DnBuffer[];
double TrBuffer[];
double trend[];
string indicatorFileName;
bool   returnBars;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   IndicatorBuffers(4);
   SetIndexBuffer(0,UpBuffer); SetIndexStyle(0,DRAW_HISTOGRAM); SetIndexLabel(0,"UpTrend");  
   SetIndexBuffer(1,DnBuffer); SetIndexStyle(1,DRAW_HISTOGRAM); SetIndexLabel(1,"DownTrend"); 
   SetIndexBuffer(2,TrBuffer); 
   SetIndexBuffer(3,trend);
     
   indicatorFileName = WindowExpertName();
   returnBars        = TimeFrame==-99;
   TimeFrame         = MathMax(TimeFrame,_Period);

   IndicatorShortName(timeFrameToString(TimeFrame)+" RSI Filter("+RsiPeriod +")");
   return(0);
}
int deinit()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int start()
{
   int i,limit,countedBars = IndicatorCounted();

   if (countedBars<0) return(-1);
   if (countedBars>0) countedBars--;
         limit = MathMin(Bars-countedBars,Bars-1);
         if (returnBars) { UpBuffer[0] = MathMin(limit+1,Bars-1); return(0); }
   
   //
   //
   //
   //
   //
   
   if (TimeFrame == _Period)
   {
      for(i = limit; i>=0; i--)
      {
         trend[i]    = trend[i+1];
         TrBuffer[i] = TrBuffer[i+1];
         DnBuffer[i] = EMPTY_VALUE;
         UpBuffer[i] = EMPTY_VALUE;
     
         //
         //
         //
         //
         //
           
         double RSI0= iRsi(iMA(NULL,0,1,0,MODE_SMA,RsiPrice,i),RsiPeriod,i,0);
            if (RSI0>70) TrBuffer[i] =  1; 
            if (RSI0<30) TrBuffer[i] = -1;
	  
            if (TrBuffer[i]>0 && RSI0 > 40) trend[i] =  1; 
            if (TrBuffer[i]<0 && RSI0 < 60) trend[i] = -1; 
            if (trend[i] == 1) UpBuffer[i] =  1;
            if (trend[i] ==-1) DnBuffer[i] = -1;
            
            //
            //
            //
            //
            //
            
            if (ShowArrows)
            {
               ObjectDelete(arrowsIdentifier+":"+Time[i]);
               if (trend[i]!=trend[i+1])
               {
                  if (trend[i] == 1)  drawArrow(i,arrowsUpColor,arrowsUpCode,false);
                  if (trend[i] ==-1)  drawArrow(i,arrowsDnColor,arrowsDnCode, true);
               }
            }
      }
      
      //
      //
      //
      //
      //
       
      if (alertsOn)
      {
         if (alertsOnCurrent)
              int whichBar = 0;
         else     whichBar = 1;
         if (trend[whichBar] != trend[whichBar+1])
         {
            if (trend[whichBar] == 1)   doAlert(whichBar,"up");
            if (trend[whichBar] ==-1)   doAlert(whichBar,"down");
         }         
      }
	return(0);
   }	   

   //
   //
   //
   //
   //
   
   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
   for (i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,TimeFrame,Time[i]);
         UpBuffer[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiPrice,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,0,y);
         DnBuffer[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,RsiPeriod,RsiPrice,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,ShowArrows,arrowsIdentifier,arrowsUpperGap,arrowsLowerGap,arrowsUpColor,arrowsDnColor,arrowsUpCode,arrowsDnCode,1,y);
   }
   return(0);	
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//
//

double workRsi[][3];
#define _price  0
#define _change 1
#define _changa 2

//
//
//
//

double iRsi(double price, double period, int shift, int forz=0)
{
   if (ArrayRange(workRsi,0)!=Bars) ArrayResize(workRsi,Bars);
      int    z     = forz*3; 
      int    i     = Bars-shift-1;
      double alpha = 1.0/(double)period; 

   //
   //
   //
   //
   //
   
   workRsi[i][_price+z] = price;
   if (i<period)
      {
         int k; double sum = 0; for (k=0; k<period && (i-k-1)>=0; k++) sum += MathAbs(workRsi[i-k][_price+z]-workRsi[i-k-1][_price+z]);
            workRsi[i][_change+z] = (workRsi[i][_price+z]-workRsi[0][_price+z])/MathMax(k,1);
            workRsi[i][_changa+z] =                                         sum/MathMax(k,1);
      }
   else
      {
         double change = workRsi[i][_price+z]-workRsi[i-1][_price+z];
                         workRsi[i][_change+z] = workRsi[i-1][_change+z] + alpha*(        change  - workRsi[i-1][_change+z]);
                         workRsi[i][_changa+z] = workRsi[i-1][_changa+z] + alpha*(MathAbs(change) - workRsi[i-1][_changa+z]);
      }
   if (workRsi[i][_changa+z] != 0)
         return(50.0*(workRsi[i][_change+z]/workRsi[i][_changa+z]+1));
   else  return(0);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[forBar]) {
          previousAlert  = doWhat;
          previousTime   = Time[forBar];

          //
          //
          //
          //
          //

           message =  StringConcatenate(Symbol()," ",timeFrameToString(_Period)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," RSI Filter ",doWhat);
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(StringConcatenate(Symbol(), Period(), " RSI Filter "),message);
             if (alertsSound)   PlaySound("alert2.wav");
      }
}

//
//
//
//
//

void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+Time[i];
   double gap  = iATR(NULL,0,20,i);   
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i] + arrowsUpperGap * gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i]  - arrowsLowerGap * gap);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

