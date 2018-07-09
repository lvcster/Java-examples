//+-----------------------------------------------------------------+
//| Price Zone 1                                                    |
//| Original auther is unknown, modification by -IXI-.              |
//+-----------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1  LimeGreen
#property indicator_color2  Orange
#property indicator_color3  Orange
#property indicator_color4  LightSlateGray
#property indicator_color5  LightSlateGray
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  1
#property indicator_width5  1
//---- Input Parameters
extern string  TimeFrame  = "current time frame";
extern int     Length     = 20;
extern double  Deviation  = 2.0;
extern bool   alertsOn        = true;
extern bool   alertsOnCurrent = false;
extern bool   alertsOnHighLow = true;
extern bool   alertsMessage   = true;
extern bool   alertsSound     = false;
extern bool   alertsNotify    = false;
extern bool   alertsEmail     = false;


//---- Buffers
double Middle[];
double MiddleI[];
double MiddleII[];
double Upper[];
double Lower[];
double Slope[];
double trend[];
string indicatorFileName;
bool   returnBars;
int    timeFrame;

//-------------------------------------------------------
//
//-------------------------------------------------------
//
//
//
//
//

int init()
  {
   IndicatorBuffers(7);
   SetIndexBuffer(0,Middle);
   SetIndexBuffer(1,MiddleI);
   SetIndexBuffer(2,MiddleII);
   SetIndexBuffer(3,Upper);
   SetIndexBuffer(4,Lower);
   SetIndexBuffer(5,Slope);
   SetIndexBuffer(6,trend);
      timeFrame         = stringToTimeFrame(TimeFrame);
      indicatorFileName = WindowExpertName();
      returnBars        = TimeFrame == "returnBars";     if (returnBars)     return(0);
   IndicatorShortName("Price Zone("+Length+")");
   return(0);
  }
int deinit() { return(0); }

//-------------------------------------------------------
//
//-------------------------------------------------------
//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
      if (counted_bars<0) return(-1);
      if (counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { Middle[0] = limit+1; return(0); }
         if (timeFrame!=Period())
         {
            limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
            if (Slope[limit]==-1) CleanPoint(limit,MiddleI,MiddleII);
            for(int i=limit; i>=0; i--)
            {
               int y = iBarShift(NULL,timeFrame,Time[i]);               
                 Upper[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Length,Deviation,alertsOn,alertsOnCurrent,alertsOnHighLow,alertsMessage,alertsSound,alertsNotify,alertsEmail,3,y);
                 Lower[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Length,Deviation,alertsOn,alertsOnCurrent,alertsOnHighLow,alertsMessage,alertsSound,alertsNotify,alertsEmail,4,y);
                 Slope[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Length,Deviation,alertsOn,alertsOnCurrent,alertsOnHighLow,alertsMessage,alertsSound,alertsNotify,alertsEmail,5,y);
                 Middle[i]  = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",Length,Deviation,alertsOn,alertsOnCurrent,alertsOnHighLow,alertsMessage,alertsSound,alertsNotify,alertsEmail,0,y);
	              MiddleI[i]  = EMPTY_VALUE;
	              MiddleII[i] = EMPTY_VALUE;
                     if (Slope[i] == -1) PlotPoint(i,MiddleI,MiddleII,Middle);
                     
            }
            return(0);
         }
         if (Slope[limit]==-1) CleanPoint(limit,MiddleI,MiddleII);

   //
   //
   //
   //
   //
   
   for (i = limit; i>=0; i--)
   {	
	   double CloseMA     = iEma(Close[i]      ,Length,i,0);
	   double HLMA        = iEma(High[i]-Low[i],Length,i,1);
	   double APZRange    = iEma(HLMA          ,Length,i,2);
	          Middle[i]   = iEma(CloseMA       ,Length,i,3);
	          Upper[i]    = Middle[i]+APZRange*Deviation;
	          Lower[i]    = Middle[i]-APZRange*Deviation;
	          Slope[i]    = Slope[i+1];
	          MiddleI[i]  = EMPTY_VALUE;
	          MiddleII[i] = EMPTY_VALUE;
   	          if (Middle[i] > Middle[i+1]) Slope[i] =  1;
                if (Middle[i] < Middle[i+1]) Slope[i] = -1;
                if (Slope[i] == -1) PlotPoint(i,MiddleI,MiddleII,Middle);
                trend[i] = 0;                     
                if (alertsOnHighLow)       
                {
                  if (High[i] > Upper[i]) trend[i] = -1;
                  if (Low[i]  < Lower[i]) trend[i] =  1;
                }
                else
                {
                  if (Close[i] > Upper[i]) trend[i] = -1;
                  if (Close[i] < Lower[i]) trend[i] =  1;
                }
   }
   manageAlerts();
	return(0);
}

//-------------------------------------------------------
//
//-------------------------------------------------------
//
//
//
//
//

double workEma[][4];
double iEma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= Bars) ArrayResize(workEma,Bars); r = Bars-r-1;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//-------------------------------------------------------
//
//-------------------------------------------------------
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i] != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
      second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}
void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
      {
       if (first[i+2] == EMPTY_VALUE)
         {
          first[i]   = from[i];
          first[i+1] = from[i+1];
          second[i]  = EMPTY_VALUE;
         }
       else
         {
          second[i]   =  from[i];
          second[i+1] =  from[i+1];
          first[i]    = EMPTY_VALUE;
         }
      }
   else
      {
       first[i]  = from[i];
       second[i] = EMPTY_VALUE;
      }
 }
 
 //-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string stringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int char = StringGetChar(s, length);
         if((char > 96 && char < 123) || (char > 223 && char < 256))
                     s = StringSetChar(s, length, char - 32);
         else if(char > -33 && char < 0)
                     s = StringSetChar(s, length, char + 224);
   }
   return(s);
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; 
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] == 1) doAlert(whichBar,"lower");
         if (trend[whichBar] ==-1) doAlert(whichBar,"upper");
      }         
   }
}

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

       message =  StringConcatenate(timeFrameToString(Period())+" "+Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," Price Zone price touching ",doWhat," band");
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(StringConcatenate(Symbol(), Period() ," Price Zone " +" "+message));
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," Price Zone "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}